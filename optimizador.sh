#!/usr/bin/bash
echo -e "\t\t\t\t" `hostname` "" `ifconfig |awk 'NR==2 { print $2 }'`
echo -e "\t\t\t\t" `date`
echo -e "\t\t\t\t" "============================\n"
echo 'PARAMETROS ACTUALES'
echo '-------------------'

totMem=`free -t|grep Mem:|awk '{print $2}'`
echo 'Memoria RAM          =' $totMem            '  KB (kilobytes)'

pgSize=`getconf PAGE_SIZE`
echo 'PAGE_SIZE            =' $pgSize            '     B (bytes)'

shmall=`cat /proc/sys/kernel/shmall`
echo 'shmall               =' $shmall            '  Paginas'

shmmax=`cat /proc/sys/kernel/shmmax`
echo 'shmmax               =' $shmmax            ' B (bytes)'

sql=`/usr/bin/psql template1 --command "SELECT name, setting FROM pg_settings WHERE name IN ('shared_buffers', 'work_mem', 'maintenance_work_mem', 'effective_cache_size', 'max_connections') ORDER BY 1;"|awk 'NR > 2 && NR < 8'`

echo 'effective_cache_size =' `echo $sql|awk '{print $3}'` '     KB'

echo 'maintenance_work_mem =' `echo $sql|awk '{print $6}'` '    KB'

maxConnections=`echo $sql|awk '{print $9}'`
echo 'max_connections      =' $maxConnections '      Conexiones (Se mide en unidades)'

echo 'shared_buffers       =' `echo $sql|awk '{print $12}'` '     Bloques'

echo 'work_mem             =' `echo $sql|awk '{print $15}'` '     KB'
echo -e '\n'


echo 'PARAMETROS PROPUESTOS'
echo '---------------------'
echo

echo -e '\tParametros de configuracion de PostgreSQL (postgresql.conf)'
echo -e '\t-----------------------------------------------------------\n'

sharedBuffers=$(($totMem/10/8))
echo 'shared_buffers       =' $sharedBuffers    '    Bloques de memoria o buffers de 8KB (8192 B)' $sharedBufferes
echo '                                 Es decir,' $(($sharedBuffers*8)) 'KB o' $(($sharedBuffers*8192)) 'B (10% de la RAM)'

echo 'work_mem             =' $(($totMem*2/100)) '    KB (2% de la RAM, 50 usuarios coparian la memoria)'

echo 'maintenance_work_mem =' $(($totMem*6/100)) '   KB (6% de la RAM)'

#effective=`free -t|grep Mem:|awk '{print $4}'`
#echo 'effective_cache_size =' $effective         '   KB (Memoria RAM libre o sin utilizar)'
echo 'effective_cache_size =' $(($totMem*4/10)) '   KB (40% de la RAM)'
echo

echo -e '\tParametros del nucleo LINUX de la Memoria Compartida'
echo -e '\t----------------------------------------------------'
echo
echo 'shmall               =' $(($totMem*1024*9/10/$pgSize)) '   Paginas (90% de la RAM)'

# Calcula y luego Redondea hacia arriba similar al comando ceil()
shmmax=`awk 'BEGIN { shmmax = 250*1024 + 8.2 * 1024 * '$sharedBuffers' + 14.2 * 1024 * '$maxConnections';
                     printf("%d\n", shmmax + 0.5);
                   }'`
echo 'shmmax               =' $shmmax 'B (Formula= 250 kB + 8.2 kB * shared_buffers + 14.2 kB * max_connections hasta el infinito)'
echo

exit


Linux 
The default maximum segment size is 32 MB, which is only adequate for small PostgreSQL installations. However, the remaining defaults are quite generously sized, and usually do not require changes. The maximum shared memory segment size can be changed via the sysctl interface. For example, to allow 128 MB, and explicitly set the maximum total shared memory size to 2097152 pages (the default):

$ sysctl -w kernel.shmmax=134217728
$ sysctl -w kernel.shmall=2097152In addition these settings can be saved between reboots in /etc/sysctl.conf. 

Older distributions might not have the sysctl program, but equivalent changes can be made by manipulating the /proc file system:

$ echo 134217728 >/proc/sys/kernel/shmmax
$ echo 2097152 >/proc/sys/kernel/shmall


# echo "kernel.shmmax=346769408" >> /etc/sysctl.conf
# echo "346769408" > /proc/sys/kernel/shmmax
# sysctl -w kernel.shmmax=346769408

Ejecute sysctl con el parametro -p para cargar los valores de sysctl desde el archivo por omision etc/sysctl.conf:
   sysctl -p





IBM - DB2 y SHMALL= 90% de la RAM
---------------------------------
SHMALL esta establecido en 8 GB por omision 8388608 KB = 8 GB). Si tiene mas memoria fisica que esta y se debe utilizar
para DB2, se deberia incrementar este parametro al 90% aproximadamente de la memoria fisica especificada para el sistema.

THE PYTHIAN GROUP y SHMALL=75% de la RAM
----------------------------------------
The Pythian Group is a remote DBA firm that offers full database support for Oracle, MySQL, and SQL Server,
including monitoring, reporting, and 24/7/365

Making shmall larger than free RAM is a recipe for paging hell and much gnashing of teeth.
Oracle recommends half the RAM.
We pushed the envelope and chose 75% as 8 gigabytes of free for OS and cache is just wasteful
