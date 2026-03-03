library(ggplot2)
library(dplyr)
library(RColorBrewer)
library(ggrepel)

zy_pie <- function(dt, value="count", fill="name", facet_my=NULL, col=NULL, digits=4){
    myplot <- function(plot_dt, col){
        ggplot(plot_dt, aes(x = "", y = Perc , fill = fill)) +
            geom_bar(stat = "identity", width = 1 , color = "white", show.legend = T) +
            geom_text_repel(aes(x = 1.5,y=1-ypos, label = label)
                            ,color="black"
                            ,nudge_x = 0.3
                            ,hjust=0
                            ,size = 3
                            , segment.color = "gray50"
                            ,force=2
                            , min.segment.length = 0
                            ,box.padding = 0.5
                            ,segment.size = .2) + 
            coord_polar("y",start = 0) +
            theme(panel.background = element_rect(fill = "transparent", color = "transparent"),
                  panel.grid = element_blank(),
                  legend.key = element_rect(fill = 'transparent'), 
                  axis.text.x = element_blank(),
                  axis.ticks = element_blank(),
                  axis.title = element_blank())+
            scale_fill_manual(values=col)
    }
    
    total_color1 = c(brewer.pal(12,"Set3"), brewer.pal(12,"Paired"))
    
    if(typeof(col) == "NULL"){
        if( nrow(unique(dt[,fill, drop=F])) > length(total_color1) ){
            message("ERROR!!!\n分类太多，请不要超过默认的24个")
            exit(1237)
        }else{
            col = total_color1[1:nrow(unique(dt[,fill, drop=F]))]
        }
    }

    if (typeof(facet_my) == "NULL"){
        data = dt[, c(fill,value)]
        colnames(data) = c("fill", "value")
        data = data[order(data$value, decreasing=F), ]

        data$fill = factor(data$fill, levels=unique(data$fill))

       
        data$ss2 = sum(data$value)
        plot_dt <- data %>% data.frame() %>%
            mutate(
                Perc =  round(value/ss2, digits=digits) # 分组计算百分比,两位小数
                ,label = paste0(fill, ", ", value," (", round((Perc)*100, digits = digits), "%)")
                ,ypos = cumsum(Perc) - 0.5 * Perc
                ,wght=runif(length(fill))
                ,wght=wght/sum(wght)
                ,wght=round(wght, digits=digits)
            )
        return(myplot(plot_dt, col))
    }else{
        data = dt[, c(fill,value, facet_my)]
        colnames(data) = c("fill", "value", "facet_my")
        fill_ord <- data %>%
            group_by(fill) %>% summarise(tot = sum(value)) %>% arrange(tot)
        
        # data = data[order(data$value, decreasing=F), ]
        data$fill = factor(data$fill, levels=fill_ord$fill)
        plot_dt <- data %>%
            arrange(facet_my, fill) %>%
            group_by(facet_my) %>%
            mutate(ss2=sum(value)
                   ,Perc =  round(value/ss2, digits=digits)
                   ,label = paste0(fill, " ,", value," (", round((Perc)*100, digits = digits), "%)")
                   ,ypos = cumsum(Perc) - 0.5 * Perc
                   ,wght=runif(length(fill))
                   ,wght=wght/sum(wght)
                   ,wght=round(wght, digits=digits)
                   )
        return(myplot(plot_dt, col) +
            facet_grid(.~facet_my))
    }

}
