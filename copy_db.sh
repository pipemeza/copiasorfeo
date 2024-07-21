#!/bin/bash

# Variables
DB_NAME="orfeo64db"
DB_USER="orfeo62usr"
DB_HOST="localhost"
DB_PASSWORD="aesael1Aitum"
BACKUP_DIR="/opt/backup/"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
DB_BACKUP_FILE="$BACKUP_DIR/$DB_NAME-$DATE.sql"
DB_COMPRESSED_FILE="$DB_BACKUP_FILE.gz"
DIR_TO_INCLUDE="/var/lib/orfeo"
DIR_COMPRESSED_FILE="$BACKUP_DIR/orfeo-$DATE.tar.gz"
FTP_SERVER="ftp://ftp.cedimips.com/"
FTP_USER="malvinas@hospitalmalvinas.com"
FTP_PASSWORD="Pipemeza:)2312"
FTP_UPLOAD_PATH="copias"


# Crear directorio de respaldo si no existe
mkdir -p $BACKUP_DIR
sudo chmod 755 $BACKUP_DIR

# Realizar backup
export PGPASSWORD=$DB_PASSWORD
pg_dump -U $DB_USER -h $DB_HOST -F c -b -v -f $DB_BACKUP_FILE $DB_NAME

# Verificar si el backup se creó correctamente
if [ ! -f $DB_BACKUP_FILE ]; then
  echo "Error: No se pudo crear el archivo de backup."
  exit 1
else
  echo "Backup de base de datos creado correctamente: $DB_BACKUP_FILE"
fi

# Comprimir el archivo de backup de la base de datos
gzip $DB_BACKUP_FILE

# Verificar si la compresión fue exitosa
if [ ! -f $DB_COMPRESSED_FILE ]; then
  echo "Error: No se pudo comprimir el archivo de backup."
  exit 1
else
  echo "Archivo de base de datos comprimido correctamente: $DB_COMPRESSED_FILE"
fi


# Comprimir la carpeta adicional
tar -czvf $DIR_COMPRESSED_FILE -C /var/lib orfeo

# Verificar si la compresión de la carpeta fue exitosa
if [ ! -f $DIR_COMPRESSED_FILE ]; then
  echo "Error: No se pudo comprimir la carpeta."
  exit 1
else
  echo "Carpeta comprimida correctamente: $DIR_COMPRESSED_FILE"
fi

# Subir archivo comprimido de la base de datos al FTP
curl -T $DB_COMPRESSED_FILE $FTP_SERVER$FTP_UPLOAD_PATH/ --user $FTP_USER:$FTP_PASSWORD

# Mensaje de finalización
if [ $? -eq 0 ]; then
  echo "Backup completado, comprimido y subido: $DB_COMPRESSED_FILE"
else
  echo "Error al subir el backup de la base de datos al FTP"
fi


# Subir archivo comprimido de la carpeta al FTP
curl -T $DIR_COMPRESSED_FILE $FTP_SERVER$FTP_UPLOAD_PATH/ --user $FTP_USER:$FTP_PASSWORD

# Verificar si la subida del archivo de la carpeta fue exitosa
if [ $? -eq 0 ]; then
  echo "Carpeta comprimida subida correctamente: $DIR_COMPRESSED_FILE"
else
  echo "Error al subir la carpeta comprimida al FTP"
fi

# Desexportar la variable de entorno PGPASSWORD por seguridad
unset PGPASSWORD

# Eliminar respaldos antiguos, solo dejar los archivos de los últimos dos días
find $BACKUP_DIR -type f -name "*.gz" -mtime +2 -exec rm {} \;


