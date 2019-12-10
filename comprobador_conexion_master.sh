#!/bin/bash

########################## Este script se ejecutara cada 10 minutos #######################################

### Intentamos levantar el servidor
#wakeonlan "MAC:direccion fisica del servidor"
colorverde=$(echo -e "\e[32m[OK]\e[0m")
colorrojo=$(echo -e "\e[31m[Error]\e[0m")
colordone=$(echo -e "\e[33m[Done]\e[0m")
colorstart=$(echo -e "\e[37m[Start]\e[0m")
colordone=$(echo -e "\e[33m[Done]\e[0m")

fecha=$(date +'%a %b %e %H:%M:%S %Z %Y')

comprobacion=$(cat /var/log/valor.txt | cut -c 1)

echo "Arrancando Script -------------------------------------- $colorverde"

if [ "$comprobacion" == "1" ]; then
echo "Haciendo ping al SV-Main ------------------------------- $colorstart"

contador=0
suma=0
contador_servicios=0

until [ $contador -eq 5 ]; do
sleep 5; ping -c 1 10.8.0.12 &> /dev/null
ping=$(echo $?)
if [ $ping -eq 0 ]; then
echo "Se ha realizado conexion ------------------------------- $colorverde"
let suma=$suma+1
else
echo "No se ha podido establecer conexion -------------------- $colorrojo"
fi
let contador=$contador+1
done




if [ "$suma" -eq 5 ]; then
echo " "
echo "Apagando los servicios"

systemctl stop bacula-director
estado=$(ps awx | grep bacula-dir | grep -v grep | wc -l)

if [ $estado -eq 0 ]; then
echo "El servicio se ha apagado correctamente -------------------- $colorverde" 
let contador_servicios=$contador_servicios+1
else
echo "El servicio bacula-dir no se ha apagado correctamente ------ $colorrojo"
echo "El servicio bacula-dir no se ha apagado correctamente [script: comprobador_conexion_master.sh]" >> /var/log/logs_comprobador
fi

systemctl stop bacula-sd
estado1=$(ps awx | grep bacula-sd | grep -v grep | wc -l)
if [ $estado1 -eq 0 ]; then
echo "El servicio se ha apagado correctamente ------------------- $colorverde"
let contador_servicios=$contador_servicios+1
else
echo "El servicio bacula-sd no se ha apagado correctamente ------- $colorrojo"
echo "El servicio bacula-sd no se ha apagado correctamente [script: comprobador_conexion_master.sh]" >> /var/log/logs_comprobador
fi

systemctl stop bacula-fd
estado2=$(ps awx | grep bacula-fd | grep -v grep | wc -l)
if [ $estado2 -eq 0 ]; then
echo "El servicio se ha apagado correctamente ------------------- $colorverde"
let contador_servicios=$contador_servicios+1
else
echo "El servicio bacula-fd no se ha apagado correctamente ------ $colorrojo"
echo "El servicio bacula-fd no se ha apagado correctamente [script: comprobador_conexion_master.sh]" >> /var/log/logs_comprobador
fi

if [[ "$contador_servicios" == "3" ]]; then
	sleep 60; echo "0" > /var/log/valor.txt # Le tiramos el valor 0 para que el script script.sh sepa que tiene que seguir comprobando 
else
	echo "No se ha podido apagar los servicio correctamente, se cancela el proceso de dar el rol al SV-Master"
	echo "No se ha podido apagar los servicio correctamente $fecha" >> /var/log/logs_comprobador
fi


fi  ### es de la comprobacion de suma igual a 5


else ### del if linea 12

echo "El control lo tiene SV-MASTER"

fi ### Del if linea 12

### Log de actividad
echo "El script: reinicio.sh se ha ejecutado a las $fecha" >> /var/log/logs_comprobador

echo " "
echo "El script ha finalizado $colordone"
