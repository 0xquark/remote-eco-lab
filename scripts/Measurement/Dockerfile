# Use Ubuntu as the base image
FROM ubuntu:22.04

# Set environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Add PPAs for additional R packages and system libraries
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:marutter/rrutter4.0 && \
    add-apt-repository -y ppa:c2d4u.team/c2d4u4.0+ && \
    apt-get update -qq

# Install R and necessary system packages
RUN apt-get install -y r-base libxml2-dev libcurl4-openssl-dev libssl-dev wget git

# Install R packages from CRAN
RUN R -e "install.packages(c('tidyr', 'dplyr', 'lubridate', 'psych', 'rmarkdown', 'rjson', 'readr', 'reshape2', 'RColorBrewer', 'tinytex'), repos = 'http://cran.r-project.org')" && \
    R -e "tinytex::install_tinytex()" && \
    R -e "tinytex::tlmgr_install('babel-english')"

# Clone the remote-eco-lab repository, copy preprocessing and measurement scripts, and remove the repository
RUN git clone https://invent.kde.org/teams/eco/remote-eco-lab.git && \
    cp remote-eco-lab/scripts/Preprocessing/Preprocessing.R ~ && \
    cp remote-eco-lab/scripts/Measurement/* ~ && \
    rm -rf remote-eco-lab
