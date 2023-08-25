FROM rocker/verse:4.3.1

## Declares build arguments
ENV NB_USER joyvan
ENV NB_UID 1000
#ENV R_LIBS_USER /opt/r
ENV DEBIAN_FRONTEND=noninteractive
ENV DISABLE_AUTH true

RUN adduser --disabled-password --gecos "Default Jupyter User" ${NB_USER}
#RUN mkdir -p ${R_LIBS_USER} && chown ${NB_USER}:${NB_USER} ${R_LIBS_USER}

# copies files from build directory to ${HOME} so they can be accessed - apt.txt, install.R, test.qmd
COPY --chown=${NB_USER} . ${HOME}

#RUN echo "${LC_ALL} UTF-8" > /etc/locale.gen && \
#    locale-gen

RUN pwd

USER root
RUN echo "Checking for 'apt.txt'..." \
        ; if test -f "apt.txt" ; then \
        apt-get update --fix-missing > /dev/null\
        && xargs -a apt.txt apt-get install --yes \
        && apt-get clean > /dev/null \
        && rm -rf /var/lib/apt/lists/* \
        ; fi

## Run an install.R script, if it exists. - do so as root, because it will use
#  the system site-library to store the packages into, so they're universally accessible
# RLIB /usr/local/lib/R/site-library/ (set inside install.R)
RUN if [ -f install.R ]; then R --quiet -f install.R; fi

################################################################################
#
#  Make sure a full quarto render is supported inside the container
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

RUN quarto render test.qmd --to pdf

#
################################################################################

RUN rm README.md test.qmd test.pdf quarto.R LICENSE install.R apt.txt 
