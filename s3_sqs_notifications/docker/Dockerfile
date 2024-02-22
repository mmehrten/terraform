FROM opensearchproject/data-prepper:latest 
COPY run.sh .
COPY pipelines/*.yaml ./pipelines/
RUN ls
RUN ls
ENTRYPOINT [ "run.sh" ]
