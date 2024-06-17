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
The Remote Eco Lab project aims to provide a streamlined process for measuring software energy consumption remotely using a CI/CD pipeline. By automating the measurement process and integrating with the OSCAR tool, developers can make informed decisions to improve code efficiency and obtain software eco-certification with the Blue Angel.
For further details on measuring the energy consumption of software, please refer to: [eco.kde.org/handbook](https://eco.kde.org/handbook/)
## Getting Started
This will help you get started with measuring your software energy consumption

If you have any trouble while performing any of the below steps, refer to this tutorial video for help: 

![KEcolab-Tutorial](KEcolab-Tutorial.mp4) 

### Pre-requistes 
Ensure you have the following prerequisites in place:
 - Application Package Name (e.g., for "kate", use "org.kde.kate")
 - Usage Scenario Scripts (Standard Usage Scenario, Idle Scenario, Baseline Scenario) : To create these scripts, follow the guidelines provided in [How to measure your software](https://eco.kde.org/handbook/#a-how-to-measure-your-software). Various tools, such as [KdeEcoTest](https://invent.kde.org/teams/eco/feep/-/tree/master/tools/KdeEcoTest), [Xdotool](https://github.com/jordansissel/xdotool) etc. can be used for script creation.
 - Basic Git knowledge

Note: In case you need to add any external files required for testing of your software, you can put them at this location `scripts/test_scripts/application_package_name/`. These files will be saved in the `/tmp/` directory on the KEcolab system.

### Format of Input Usage Scripts:
 - Ensure your input scripts adhere to the following format:
   - Standard Usage Scenario (filename: log_sus.sh): 
        The required format for the column header is `iteration no;yy-mm-dd hh:mm:ss;startTestrun`
        The sequence should be: startTestrun, startAction, and then stopAction.
        Example of Standard Usage Scenario
        ```
        iteration 1;2023-08-10 18:14:44;startTestrun
        iteration 1;2023-08-10 18:14:54;startAction;go to line 100 
        iteration 1;2023-08-10 18:14:59;stopAction
        ```
   - Idle Scenario (filename: log_idle.sh):
       The required format is `iteration no;yy-mm-dd hh:mm:ss;startTestrun`
       Example of idle scenario:
       ```
       iteration 1;2023-08-10 18:21:35;startTestrun 
       iteration 1;2023-08-10 18:22:09;stopTestrun 
       ```
   - Baseline Scenario (filename: log_baseline.sh):
        The required format is `iteration no;yy-mm-dd hh:mm:ss;startTestrun`
        Example of baseline scenario:
        ```
        iteration 1;2023-08-10 18:20:53;startTestrun 
        iteration 1;2023-08-10 18:21:13;stopTestrun 
        ```
Note: Ensure filenames match exactly as specified above, and the format precisely adheres to the given examples.
## Usage
First, prepare the three usage scenario scripts on your system.
### Creating a Merge Request
- Fork or clone the Remote Eco Lab repository to your GitLab account.
- Create a new branch in your fork/clone and add the usage scenario scripts in the path `scripts/test_scripts/application_package_name/` (for example, scripts/test_scripts/org.kde.kate/log_sus.sh).
- Push the changes and initiate a merge request, using the application package name as the title. For example, `org.kde.kate`.
### Review and Approval
- Sit back and relax while your proposed application is reviewed for any potential security risks.
### CI/CD Pipeline Execution
- Upon approval, the CI/CD pipeline will be triggered automatically.
The pipeline comprises the following stages:
  - Build: In this stage, the Flatpak version of the app is installed.
  - Energy_measurement: This stage focuses on remote energy consumption measurement, involving interactions with the Lab Test PC, Power Meter, and Raspberry PI. The usage scenario scripts are run while readings from the Power Meter and hardware data are collected using the `collectl` tools. These are available as artifacts from this stage.
  - Result: The energy measurement results obtained are used as input for OSCAR (Open-source Software Consumption Analysis in R) analysis. The OSCAR script generates a report file summarizing energy consumption measurements and provides visualizations, available as an artifact.

## Accessing the results:
### Downloading Artifacts and Analyzing Results with OSCAR  :
   - Energy measurement artifacts can be found at [Job Artifacts](https://invent.kde.org/teams/eco/remote-eco-lab/-/artifacts) under the energy_measurement stage.
   - The final Energy measurement report is also available at [Job Artifacts](https://invent.kde.org/teams/eco/remote-eco-lab/-/artifacts) under the Result stage.
   - Utilize the energy measurement report to analyze energy consumption during various actions and leverage this information to enhance your application's energy efficiency or to pursue eco certification with the Blue Angel ecolabel.

### Conclusion 
By automating the energy measurement process and providing remote access, we make it possible for developers to measure the energy consumption of their software from any location in the world. The increased access to the lab will enable data-driven decision-making for efficiency improvements in code and software eco-certification with agencies like the Blue Angel.

### How to Contribute?
For discussions about KDE Eco's energy measurement lab, including updates, technical discussions, bug reporting, and general feedback: https://go.kde.org/matrix/#/#kde-eco-dev:kde.org on Matrix.

For other ways to get involved with KDE Eco: https://eco.kde.org/get-involved/
