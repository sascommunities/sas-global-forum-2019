# Using SAS  Viya  to Implement Custom SAS  Analytics in Python: A Cybersecurity Example

We demonstrate two analytics environments developed for the SAS® Cybersecurity solution that combine SAS and open source tools. The first, an **exploration and discovery environment**, supports investigation of data and hypothesis testing. Insights gained on static data in this environment can then be implemented in a **production environment** that supports analytic calculations on streaming data. The results of these calculations feed an alerting system that highlights anomalous events found in the streaming data. Using these environments, data scientists implement SAS analytics in Python. Though designed for cybersecurity, the core environment is extensible to other analytic scenarios.

The environment’s foundation is built with SAS® Viya. A custom Python module implements 78 predefined cybersecurity analytics that orchestrate SAS® Cloud Analytic Services (CAS) via the SAS developed, open source `python-swat` module. Analytics are easily tuned and configured using JSON formatted support files. A data scientist can create custom analytics with the same Python framework that implements the preconfigured analytics.

Alongside this paper, we share a sample version of the python module that readers can use as a base to develop their own analytics that run in CAS. The provided sample builds a Docker container that delivers the python module, SAS python-swat, sample Jupyter notebooks, and a sample dataset of Windows Host Events from the Los Alamos National Laboratory Unified Host and Network datasets.

We chose the language, tools, and architecture presented here specifically for the quality, popularity, and ease of use they provide. SAS Viya provides world class in-memory analytics; Python is popular among data scientists and easily scales to enterprise deployments; and Jupyter is a standard, accepted environment for prototyping data science solutions. Our Python module simplifies interaction with CAS by abstracting connection, management, and analytic details one level higher from the SWAT framework. The abstraction allows the module to operate in a production environment and perform calculations in response to data availability, instead of in response to a user-driven request. The use cases for such an analytic architecture range from instructional delivery in education through production data science solutions. The SAS Viya / Python / Jupyter combination demonstrated here is an exciting option for data scientists looking to develop custom solutions backed by SAS analytics.

## Additional information

Find the full paper online with the [SAS Global Forum proceedings](https://www.sas.com/en_us/events/sas-global-forum/program/proceedings.html).

## Support contact(s)

Damian Herrick  
SAS Institute, Inc.  
[Damian.Herrick@sas.com](Damian.Herrick@sas.com)
