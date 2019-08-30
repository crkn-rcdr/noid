FROM perl:5.30

RUN groupadd -g 1000 perl && useradd -u 1000 -g perl -m perl && \
  cpanm -n Carton

WORKDIR /noid

COPY cpanfile* ./

RUN carton install --deployment || (cat /root/.cpanm/work/*/build.log && exit 1)

COPY minter.psgi ./

EXPOSE 3000
ENTRYPOINT ["carton", "exec"]
CMD ["starman", "minter.psgi", "-Ilib", "--port", "3000", "--workers", "1"]
