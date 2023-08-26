FROM rocker/geospatial:4.3.1

# Install conda here, to match what repo2docker does
ENV CONDA_DIR=/srv/conda

# Add our conda environment to PATH, so python, mamba and other tools are found in $PATH
ENV PATH ${CONDA_DIR}/bin:${PATH}

# RStudio doesn't actually inherit the ENV set in Dockerfiles, so we
# have to explicitly set it in Renviron.site
RUN echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron.site

# The terminal inside RStudio doesn't read from Renviron.site, but does read
# from /etc/profile - so we rexport here.
RUN echo "export PATH=${PATH}" >> /etc/profile

# Install a specific version of mambaforge in ${CONDA_DIR}
# Pick latest version from https://github.com/conda-forge/miniforge/releases
ENV MAMBAFORGE_VERSION=23.3.1-0
RUN echo "Installing Mambaforge..." \
    && curl -sSL "https://github.com/conda-forge/miniforge/releases/download/${MAMBAFORGE_VERSION}/Mambaforge-${MAMBAFORGE_VERSION}-Linux-$(uname -m).sh" > installer.sh \
    && /bin/bash installer.sh -u -b -p ${CONDA_DIR} \
    && rm installer.sh \
    && mamba clean -afy \
    # After installing the packages, we cleanup some unnecessary files
    # to try reduce image size - see https://jcristharif.com/conda-docker-tips.html
    && find ${CONDA_DIR} -follow -type f -name '*.a' -delete \
    && find ${CONDA_DIR} -follow -type f -name '*.pyc' -delete

COPY environment.yml /tmp/environment.yml
COPY test.qmd /tmp/test.qmd
COPY install.R /tmp/install.R

RUN mamba env update -p ${CONDA_DIR} -f /tmp/environment.yml \
    && mamba clean -afy \
    && find ${CONDA_DIR} -follow -type f -name '*.a' -delete \
    && find ${CONDA_DIR} -follow -type f -name '*.pyc' -delete

RUN install2.r --skipinstalled \
    tidyverse \
    learnr \
    ggplot2 \
    devtools \
    learnr \
    && rm -rf /tmp/downloaded_packages

RUN install2.r --skipinstalled IRkernel \
    && rm -rf /tmp/downloaded_packages

RUN if [ -f /tmp/install.R ]; then R --quiet -f /tmp/install.R; fi
    
RUN r -e "IRkernel::installspec(prefix='${CONDA_DIR}')"

#
#  quarto render to PDF doesn't run immediately without all these CTAN packages
#
RUN set -ux \
    && tlmgr install \
        colortbl \
        environ \
        makecell \
        multirow \
        placeins \
        tabu \
        threeparttable \
        threeparttablex \
        trimspaces \
        ulem \
        varwidth \
        wrapfig \
        xcolor \
        koma-script \
        amsmath \
        iftex \
        unicode-math \
        xcolor \
        fancyvrb \
        framed \
        booktabs \
        etoolbox \
        mdwtools \
        caption \
        float \
        tcolorbox \
        pgf \
        environ \
        tikzfill \
        pdfcol \
        ltxcmds \
        infwarerr \
        hyperref \
        kvoptions \
        bookmark 
RUN set -ux \
    tlmgr path add || true

#
#  a test
#
RUN cd /tmp/
RUN quarto render /tmp/test.qmd --to pdf

#
#  cleanup
#
RUN rm /tmp/test.qmd /tmp/install.R /tmp/environment.yml /tmp/test.pdf

# explicitly specify working directory
#WORKDIR /home/jovyan

ENV SHELL=/bin/bash
#
#  issue: the user's persistent storage is mounted at /home/jovvan
#  But all rocker images have user rstudio, and home directory at
#  /home/rstudio
#
#  So this creates the joyvan user in the image,
#  which allows its home directory to exist. It then symlinks
#  that directory to the /home/rstudio/workspace/ directory.
#
#  THEN when R starts, the .Rprofile gently boops it into the workspace
#  directory, which is ACTUALLY the /home/joyvan directory where all the
#  persistent files are stored. It's a hack, but it works, unlike the 4
#  other ways I've tried ...
#
#RUN useradd -ms /bin/bash joyvan
#RUN cd /home/rstudio; ln -s /home/jovyan/ workspace
#RUN echo "rstudioapi::filesPaneNavigate(getwd())" >> /home/rstudio/.Rprofile
#RUN chown -R rstudio:rstudio /home/rstudio/*

# new hacky try: just rename the home directory of user rstudio
RUN mkdir -p /home/jovyan; chown -R rstudio:rstudio /home/jovyan
RUN sed -i '21d' /etc/passwd; echo "rstudio:x:1000:1000::/home/jovyan:/bin/bash" >> /etc/passwd
RUN rm -rf /home/rstudio
RUN echo "setwd(\"/home/jovyan/\")" > /home/jovyan/.Rprofile 

#  supposedly will set the focus directory in the RStudio interface
#  to be the right place?
ENV EDITOR_FOCUS_DIR "/home/rstudio/workspace"


