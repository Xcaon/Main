#!/bin/bash


###################################### Este Script se ejecutara cada 1 minuto con crontab - Comando crontab -e #############################################

####################### Variables para colores ######################
colorverde=$(echo -e "\e[32m[OK]\e[0m")
colorrojo=$(echo -e "\e[31m[Error]\e[0m")
colordone=$(echo -e "\e[33m[Done]\e[0m")
colorstart=$(echo -e "\e[37m[Start]\e[0m")
colorinfo=$(echo -e "\e[37m[Info]\e[0m")
#####################################################################

fecha=$(date +'%a %b %e %H:%M:%S %Z %Y') ## variable de fecha
valor=0


echo "$colorinfo Dejar terminar el Script $colorinfo"
echo " "
echo "Comprobando los ficheros -------------------------------- $colorstart"
####################################### Comprobacion ficheros
######### Los pings
if [ -f /var/log/server_ping.txt ]; then
echo "Fichero de intentos de pings     -------------------------- $colorverde"
else
echo "Fichero de intento de ping     -------------------------- $colorrojo"
echo "Creando.."
echo " "
touch /var/log/server_ping.txt
chmod 755 /var/log/server_ping.txt
fi

######## Comprueba quien tiene el control
if [ -f /var/log/valor.txt ]; then
echo "Fichero control manager  ----------------------------- $colorverde"
else
echo "Fichero control manager  ----------------------------- $colorrojo"
echo "Creando.."
echo " "
touch /var/log/valor.txt
echo "0" > /var/log/valor.txt
fi

####### Manda logs de posibles fallos 
if [ -f /var/log/logs_comprobador.txt ]; then
echo "Fichero de Logs del script -------------------------------------- $colorverde"
else
echo "Fichero de logs del script  ------------------------------------- $colorrojo"
echo "Creando.."
echo " "
touch /var/log/logs_comprobador.txt
fi
echo " "
echo "Comprobacion de archivos ----------------------------- $colordone"
echo " "
###################################### VARIABLES ######################################
contador=0  ### contador del bucle
recuento_fallos_procesos=0
#######################################################################################

####################################### Comprobacion si esta apagado el SV-MASTER
echo " "
comprobacion=$(cat /var/log/valor.txt | cut -c 1)

if [ "$comprobacion" -eq 0 ]; then

echo "Comprobando ping con el servidor ---------------------- $colorstart"

error=0

until [ "$contador" -eq 5 ]; do

ping -c 1 10.8.0.12 &>/var/log/server_ping.txt 

pingvalor=$(echo $?)

if [ $pingvalor -eq 0 ]; then
echo "Conexion realizada ----------------------------------- $colorverde"
else
echo "Conexion no realizada -------------------------------- $colorrojo"
let error=$error+1
fi
echo "Hay $error errores"

let contador=$contador+1
done

echo " "
echo "Fin de la comprobacion ------------------------------- $colordone"


echo " "
###################################### Servicios 

if [ $error -ge 3 ]; then
echo "Ejecutando Servicios --------------------------------- $colorstart"
############################### Comprobamos si los servicios estan corriendo y si no lo estan se inician
valor=1

sdtest=$(ps awx | grep bacula-sd | grep -v grep | wc -l)
if [ $sdtest -eq 0 ]; then
systemctl start bacula-sd

sdtest1=$(ps awx | grep bacula-sd | grep -v grep | wc -l)
if [ $sdtest1 -eq 1 ]; then
echo "El servicio Bacula-sd se ha ejecutado correctamente -------------- $colorverde"
else
echo "El servicio Bacula-sd no se ha ejecutado correctamente ----------- $colorrojo"
fi

else
echo "El servicio bacula-sd estaba encendido cuando no debia [Script: started.sh]"
let recuento_fallos_procesos=$recuento_fallos_procesos+1
echo "El servicio bacula-sd estaba encendido cuando no debia [Script: started.sh] $fecha" >> /var/log/logs_comprobador
fi


dirtest=$(ps awx | grep bacula-dir | grep -v grep | wc -l)
if [ $dirtest -eq 0 ]; then
systemctl start bacula-director

dirtest1=$(ps awx | grep bacula-dir | grep -v grep | wc -l)
if [ $dirtest1 -eq 1 ]; then
echo "El servicio bacula-dir se ha ejecutado correctamente -------------- $colorverde"
else
echo "El servicio bacula-dir no se ha ejecutado correctamente ----------- $colorrojo"
fi

else
echo "El servicio bacula-dir estaba encendido cuando no debia [Script: started.sh]"
let recuento_fallos_procesos=$recuento_fallos_procesos+1
echo "El servicio bacula-dir estaba encendido cuando no debia [Script: started.sh] $fecha" >> /var/log/logs_comprobador
fi


else
echo "El Servidor principal esta funcionando correctamente, no se realizan cambios ---------- $colorverde"
echo "El Servidor principal esta funcionando correctamente, no se realizan cambios $fecha ---------- $colorverde" >> /var/log/logs_comprobador
fi
#### el fi de arriba es el del contador de errores
fi
echo " "
echo "Exit -------------------------------------------------------------- $colordone"

############################### Volcado del control manager en el fichero que puede valer 0 o 1 #####################













# ponemos el valor 1 en valor.txt para cuando el script se vuelva a ejecutar, valide si SV-SLAVE tiene el control de las copias.
if [[ $valor -eq 1 ]]; then

if [[ $recuento_fallos_procesos > 0 ]]; then
	echo "Hay un problema para levantar los procesos --------- $colorrojo"
	echo "Hay un problema para levantar los procesos $fecha --------- $colorrojo" >> /var/log/logs_comprobador
	systemctl stop bacula-director; systemctl stop bacula-fd; systemctl stop bacula-sd
else
	echo "run 1 mod 6 now yes" | bconsole
	allgood=1
fi

if [[ $allgood -eq 1 ]]; then
echo "1" > /var/log/valor.txt
fi

fi


#####################################################################################################################




####################################### La comprobacion de si se levanta el server de nuevo esta en el script - reinicio.sh

echo "El script: started.sh se ha ejecutado a las $fecha" >> /var/log/logs_comprobador

###################################### extras
### Borramos contenido de atras.txt que es el contador de errores del bucle ping
sleep 5; true > /var/log/atras.txt

