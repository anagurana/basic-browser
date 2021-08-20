# Upload to BASIC
#         Script for uploading cluster, coverage, and peak tracks
#         to BASIC browser
#         2017
#         The Jackson Laboratory for Genomic Medicine

## The help message:
function usage
{
    echo -e "usage: bash upload_to_basic.sh -c CONF
    " 
}

## Parse the command-line argument (i.e., get the name of the config file)
while [ "$1" != "" ]; do
    case $1 in
        -c | --conf )           shift
                                conf=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1docker
    esac
    shift
done

# Source the config file to get the parameter values
source ${conf}

# Set the track name
track_name="${cell_type}_${ip_factor}_${run}_${run_type}"

# Set the library name
basic_folder=chia_pet
annotation=annotation

# Set the data directory name
data_dir=/Documents


## Make file names
# Cluster file
if [ ${ip_factor} == "CTCF" ]
then
    clust_file="${run}.e500.clusters.cis.BE3"
else
    clust_file="${run}.e500.clusters.cis.BE3"
fi


# Coverage file
cov_file="${run}.for.BROWSER.sorted.bedgraph"

# Peak file
if [ ${peak_caller} == "macs2" ]
then
    # Macs2 file name template
    peak_file="${run}.no_input_all_peaks.narrowPeak"
else
    # SPP file name template
    peak_file="${run}.for.BROWSER.spp.z6.broadPeak"
fi

## Set command aliases
# Table utility
table_util="/opt/basic/_py/bin/python /opt/basic/console/table_util.py"
# table_util="python /home/basic_browser/basic/basic/console/table_util.py"
# Track utility
track_util="/opt/basic/_py/bin/python /opt/basic/console/track_util.py"
# track_util="python /home/basic_browser/basic/basic/console/track_util.py"

## Initialize tracks
# Coverage track
cov_str=$( ${table_util} create ${genome} -l "${basic_folder}" \
    "${track_name} coverage" )

# Cluster track
clust_str=$( ${table_util} create ${genome} -l "${basic_folder}" \
    "${track_name} loop" )

# Peak track
peak_str=$( ${table_util} create ${genome} -l "${basic_folder}" \
    "${track_name} peak" )

# Assembly track
assc_str=$( ${table_util} create ${genome} -l "${annotation}" \
    "UCSC Known Genes (${genome})" )


## Parse the returned text to get the track number
# Coverage number
cov=$( echo ${cov_str} | \
    grep -o "[[:space:]][0-9]*[[:space:]]" | xargs )

# Cluster number
clust=$( echo ${clust_str} | \
    grep -o "[[:space:]][0-9]*[[:space:]]" | xargs )

# Peak number
peak=$( echo ${peak_str} | \
    grep -o "[[:space:]][0-9]*[[:space:]]" | xargs )

# Assembly number
assc=$( echo ${assc_str} | \
    grep -o "[[:space:]][0-9]*[[:space:]]" | xargs )


## Configure tracks
# Load file to cluster track
${table_util} load ${clust} \
    1:chrom 2:start 3:end 4:chrom2 5:start2 6:end2 7:score \
    -i ${data_dir}/${clust_file}

# Set drawing types for cluster track
${track_util} new ${clust} pcls
${track_util} new ${clust} curv

# Load file to peak track
if [ $peak_caller == "macs2" ]
then
    # Macs2 file format
    ${table_util} load ${peak} \
        1:chrom 2:start 3:end 4:name 5:score \
        -i ${data_dir}/${peak_file}
else
    # SPP file format
    ${table_util} load ${peak} \
        1:chrom 2:start 3:end 7:name 7:score \
        -i ${data_dir}/${peak_file}
fi

# Set drawing type for peak track
${track_util} new ${peak} scls

# Load file to coverage track
${track_util} gen_cov max ${cov} ${data_dir}/${cov_file}

# Genome Assembly 
table_util load_genes ${assc} -i ${data_dir}/data/dm3_known_genes.txt --assoc \
${data_dir}/data/gene_association.goa_fly --terms ${data_dir}/data/GO.terms_alt_ids
track_util gen_genes ${genome}
