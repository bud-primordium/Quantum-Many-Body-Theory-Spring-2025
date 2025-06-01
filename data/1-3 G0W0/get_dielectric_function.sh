
file="vasprun.xml"
outfile1="dielectric_function_IPA.dat"
outfile2="dielectric_function_RPA.dat"


echo "Extracting HEAD OF MICROSCOPIC DIELECTRIC TENSOR (INDEPENDENT PARTICLE) from $file"
awk 'BEGIN{i=0} /HEAD OF MICRO/,\
                /\/real/ \
                 {if ($1=="<r>") {a[i]=$2 ; b[i]=$3 ; c[i]=$4 ; d[i]=$5 ; i=i+1}} \
     END{for (j=0;j<i/2;j++) print a[j],b[j],b[j+i/2]}' $file > $outfile1
echo "Written to $outfile1"

echo "Extracting INVERSE MACROSCOPIC DIELECTRIC TENSOR (including local field effects in RPA (Hartree)) from $file"
awk 'BEGIN{i=0} /INVERSE MACRO/,\
                /\/real/ \
                 {if ($1=="<r>") {a[i]=$2 ; b[i]=$3 ; c[i]=$4 ; d[i]=$5 ; i=i+1}} \
     END{for (j=0;j<i/2;j++) print a[j],b[j],b[j+i/2]}' $file > $outfile2
echo "Written to $outfile2"
