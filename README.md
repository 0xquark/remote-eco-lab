# KEcoLab
Welcome to the KEcoLab GitLab repository! This project enables you to measure energy consumption of your software remotely using a CI/CD pipeline. Follow the steps below to get started.
## Table of Contents
- Introduction
- Getting Started
    - Prerequisites
    - Format of the input scripts
- Usage
   - Creating a Merge Request
   - Review and Approval
   - CI/CD Pipeline Execution
- Accessing Results
   - Downloading Artifacts and Analyzing Results with OSCAR 
- Conclusion
- How to Contribute?

## Introduction 
The Remote Eco Lab project aims to provide a streamlined process for measuring software energy consumption remotely using a CI/CD pipeline. By automating the measurement process and integrating with the OSCAR tool, developers can make informed decisions to improve code efficiency and work towards software eco-certification.
For further details on measuring energy consumption of software, please refer to : [eco.kde.org/handbook](https://eco.kde.org/handbook/)
## Getting Started
This will help you get started with measuring your software energy consumption
### Pre-requistes 
Before diving in, ensure you have the following prerequisites in place:
 - Application Package Name (For eg. For kate i.e org.kde.kate )
 - Usage Scenario Scripts ( log_sus.sh, log_baseline.sh, log_idle.sh ) : To create these scripts, follow the guidelines provided in [How to measure your software](https://eco.kde.org/handbook/#a-how-to-measure-your-software). Various tools, such as [KdeEcoTest](https://invent.kde.org/teams/eco/feep/-/tree/master/tools/KdeEcoTest), [Xdotool](https://github.com/jordansissel/xdotool) etc. can be used for script creation.
 - Basic Git knowledge

### Format of Input Usage Scripts:
 - Ensure your input scripts adhere to the following format:
   - log_sus.sh : 
        The required format is `iteration no;yy-mm-dd hh:mm:ss;startTestrun`
        The sequence should be: startTestrun, startAction, and then stopAction.
        Example of Standard Usage Scenario
        ```
        iteration 1;2023-08-10 18:14:44;startTestrun
        iteration 1;2023-08-10 18:14:54;startAction;go to line 100 
        iteration 1;2023-08-10 18:14:59;stopAction
        ```
   - log_baseline.sh :
        The required format is `iteration no;yy-mm-dd hh:mm:ss;startTestrun`
        Example of baseline scenario:
        ```
        iteration 1;2023-08-10 18:20:53;startTestrun 
        iteration 1;2023-08-10 18:21:13;stopTestrun 
        ```
   - log_idle.sh :
       The required format is `iteration no;yy-mm-dd hh:mm:ss;startTestrun`
       Example of idle scenario:
       ```
       iteration 1;2023-08-10 18:21:35;startTestrun 
       iteration 1;2023-08-10 18:22:09;stopTestrun 
       ```
Note: Ensure filenames match exactly as specified above, and the format precisely adheres to the given examples.
## Usage
Prepare different usage scenario files on your system.
### Creating a Merge Request
- Fork or clone the Remote Eco Lab repository to your GitLab account.
- Create a new branch in your fork/clone and add the usage scenario scripts.
- Push the changes and initiate a merge request, using the application package name as the title. For example, `org.kde.kate`.
### Review and Approval
- Sit back and relax while we review your proposed application for any potential security risks.
### CI/CD Pipeline Execution
- Upon approval, the CI/CD pipeline will be triggered automatically.
The pipeline comprises the following stages:
  - Build: In this stage, the flatpak version of the app is installed.
  - Energy_measurement: This stage focuses on remote energy consumption measurement, involving interactions with the Lab Test PC (SUT), Power Meter, and Raspberry PI (DAE). It simulates usage scenarios while collecting readings from the Power Meter and hardware data using the collectl tools. These are available as artifacts from this stage.
  - Result: The energy measurement results obtained are used as input for OSCAR (Open-source Software Consumption Analysis in R) analysis. OSCAR generates a report file summarizing energy consumption measurements and provides visualizations, available as an artifact.

## Accessing the results:
### Downloading Artifacts and Analyzing Results with OSCAR  :
   - Energy measurement artifacts can be found at [Job Artifacts](https://invent.kde.org/teams/eco/remote-eco-lab/-/artifacts) under the energy_measurement stage.
   - The final Energy measurement report is also available at [Job Artifacts](https://invent.kde.org/teams/eco/remote-eco-lab/-/artifacts) under the Result stage.
   - Utilize the energy measurement report to analyze energy consumption during various actions and leverage this information to enhance your application's energy efficiency or to pursue eco certification.

### Conclusion 
By automating the energy measurement process and providing remote access, we make it possible for developers to measure the energy consumption of their software from any location in the world. The increased access to the lab will enable data-driven decision-making for efficiency improvements in code and software eco-certification with agencies like the Blue Angel.

### How to Contribute?
For discussions about KDE Eco's energy measurement lab, including updates, technical discussions, bug reporting, and general feedback : #kde-eco-dev:kde.org on matrix