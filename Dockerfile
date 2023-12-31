FROM alpine/git as intermediate
RUN git clone https://github.com/konradjk/loftee.git /loftee

FROM alpine as download_loftee
RUN wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/human_ancestor.fa.gz -Y off
RUN wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/human_ancestor.fa.gz.fai -Y off
RUN wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/human_ancestor.fa.gz.gzi -Y off
RUN wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/gerp_conservation_scores.homo_sapiens.GRCh38.bw -Y off
RUN wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/loftee.sql.gz -Y off

FROM ensemblorg/ensembl-vep:release_110.1
# Change user to root
USER root

RUN apt-get update && apt-get install -y samtools

# Change user to vep
USER vep

RUN perl /opt/vep/src/ensembl-vep/INSTALL.pl \
        --AUTO fcp \
        --NO_UPDATE \
        --ASSEMBLY GRCh38 \
        --PLUGINSDIR /opt/vep/.vep/Plugins/ \
        --CACHEDIR /opt/vep/.vep/ \
        --PLUGINS all \
        --SPECIES homo_sapiens_merged

RUN vep -id rs699 \
      --cache --merged \
      --nearest symbol \
      -o 'STDOUT' \
      --no_stats \
      > /dev/null

COPY --from=intermediate /loftee /opt/vep/.vep/Plugins/loftee
COPY --from=download_loftee /human_ancestor.fa* /opt/vep/.vep/Plugins/loftee/data/
COPY --from=download_loftee /gerp* /opt/vep/.vep/Plugins/loftee/data/
COPY --from=download_loftee /loftee* /opt/vep/.vep/Plugins/loftee/data/