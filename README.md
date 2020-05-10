# twitter-sentiment-tracking
An application that extracts sentiments from tweets and displays them in a real-time dashboard. This application was developed as part of the course Stream Processing & Real-Time Analytics at IE School of Human Sciences and Technology to showcase a prototype using PySpark and Apache Kafka. 

It uses the tweepy library to stream tweets and to write them to a Kafka topic. A PySpark job gets the raw text and extracts the sentiments, calculates the average per minute and send it to another Kafka topic for processed data (Note: As this is just a prototype, no text preprocessing is done to the tweets). From this second Kafka topic, the sentiments are consumed by a reactive Shiny app, using sparklyr, the Spark API from R. 

![Dashboard showing average polarity and subjectivity per minute](https://github.com/danielbilitewski/twitter-sentiment-tracking/blob/master/Dashboard.png)
Image: example of how the dashboard looks in action

**How to Deploy the Application**

We assume that you already have Kafka and Spark downloaded. When building this, we used Spark version 2.4.4 and Kafka version 2.5.0. 

To start the Kafka server, use the Konsole and navigate to the folder where containing Kafka. On Windows, to start Zookeeper and Kafka, run:

`bin/windows/zookeeper-server-start.bat config/zookeeper.properties`

`bin/windows/kafka-server-start.bat config/server.properties`

On Mac and Linux, the equivalent commands are:

`bin/zookeeper-server-start.sh config/zookeeper.properties`

`bin/kafka-server-start.sh config/server.properties`

Next, you can just launch the notebooks `tweets_producer.ipynb` and `sentiment_extraction.ipynb` from Jupyter Notebooks. The dashboard `shiny_app.R` can be launched using R Studio by clicking on 'Run App'. You will see an error message which will go away after the first data point is received by the Shiny app. 
