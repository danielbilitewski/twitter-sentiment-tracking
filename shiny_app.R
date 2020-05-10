# load libraries
library(future)
library(sparklyr)
library(dplyr, warn.conflicts = FALSE)
library(ggplot2)
library(shiny)
library(reshape2)
library(shinydashboard)
library(gridExtra)
library(ggdark)

# create variables
KAFKA_TOPIC_READ <- "sentiments_covid19" # which Kafka topic to read from
Y_AXIS_LIMITS <- c(0.25, 0.75) # which y-axis range to display in the dashboard
POLARITY_TITLE <- "Polarity of tweets with hashtag #Covid_19" # title to display in dashboard
SUBJECTIVITY_TITLE <- "Subjectivity of tweets with hashtag #Covid_19" # title to display in dashboard

# create a theme for the plot
fill_color = '#171616'
decoration_color = '#cccccc'

theme_set(dark_theme_gray()+ theme(
  panel.grid.major = element_blank(), 
  panel.grid.minor = element_blank(),
  plot.title = element_text(size = 14,color = decoration_color),
  axis.ticks = element_blank(),
  axis.text = element_text(colour = decoration_color, size = 10),
  axis.title = element_text(size = 10, color = decoration_color),
  legend.title = element_blank(),
  panel.background = element_rect(fill = fill_color),
  strip.background = element_rect(fill = fill_color), 
  plot.background = element_rect(fill = fill_color),
  legend.background = element_rect(fill = fill_color)
))

# create the spark connection
sc <- spark_connect(master = "local", 
                    config = list(
                      sparklyr.shell.packages = "org.apache.spark:spark-sql-kafka-0-10_2.11:2.4.0"
                    ))

# connect to the Kafka topic and extract the relevant data
read_options = list(kafka.bootstrap.servers = "localhost:9092", 
                    subscribe = KAFKA_TOPIC_READ)

# NOTE: this stream treats the JSONs as a long string, a better solution
# would be to transform the JSON back into a dataframe, but sparklyr has
# limited functionality
process_stream <- stream_read_kafka(sc, options = read_options) %>%
  mutate(value = as.character(value)) %>%
  mutate(polarity = as.numeric(substr(value, 155, 159))) %>%
  mutate(subjectivity = as.numeric(substr(value, 186, 190))) %>%
  mutate(minute = substr(value, 23, 39)) %>%
  select(polarity, subjectivity, minute)

# create the Shiny app
shinyUI<- fluidPage(
  plotOutput("myplot",height = "800px")
)

shinyServer<-function(input, output) {
  
  # connect to the spark stream
  ps <- reactiveSpark(process_stream)
  
  # create a reactive dataframe
  dat <- reactive(ps())
  
  # create the plot
  output$myplot<- renderPlot({
    
    # the first plot shows the polarity
    g1=ggplot(data = dat(), aes(x=minute, y=polarity, group = 1)) +
      geom_point(color="#ff9f1c") +
      geom_line(color="#ff9f1c") +
      geom_hline(yintercept = 0.5,linetype="dashed") +
      scale_y_continuous(limits = Y_AXIS_LIMITS) +
      theme(panel.background = element_blank(),
            axis.ticks = element_blank(),
            axis.title = element_blank(),
            axis.text.x = element_text(face = "bold", size = 12, angle = 45),
            legend.background = element_rect(fill = "white"),
            legend.key = element_rect(fill = "white"),
            legend.title = element_blank()) +
      labs(title = POLARITY_TITLE,
           subtitle = 'From 0 = negative to 1 = negative')
    
    # the second plot shows the subjectivity
    g2=ggplot(data = dat(), aes(x=minute, y=subjectivity, group = 1)) +
      geom_point(color = "#2ec4b6") +
      geom_line(color = "#2ec4b6") +
      geom_hline(yintercept = 0.5,linetype="dashed")+
      scale_y_continuous(limits = Y_AXIS_LIMITS)+
      theme(panel.background = element_blank(),
            axis.ticks = element_blank(),
            axis.title = element_blank(),
            axis.text.x = element_text(face = "bold", size = 12, angle = 45),
            legend.background = element_rect(fill = "white"),
            legend.key = element_rect(fill = "white"),
            legend.title = element_blank()) +
      labs(title = SUBJECTIVITY_TITLE,
           subtitle = 'From 0 = objective to 1 = subjective')
    
    # arrange the plots into a grid with polarity on top and subjectivity below
    grid.arrange(g1,g2)
  })
}

# launch the Shiny app
shinyApp(ui=shinyUI, server=shinyServer)