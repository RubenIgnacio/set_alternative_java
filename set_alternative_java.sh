#!/bin/sh

JAVA_DIRNAME=$2
ALIAS=$3
PRIORITY=$4

JVM_PATH=/usr/lib/jvm
JAVA_PATH="$JVM_PATH/$JAVA_DIRNAME"
HL_PATHS='bin/rmid bin/java bin/keytool bin/jjs bin/pack200 bin/rmiregistry bin/unpack200 bin/orbd bin/servertool bin/tnameserv lib/jexec'
JDKHL_PATHS='bin/idlj bin/jdeps bin/wsimport bin/jinfo bin/jstat bin/jlink bin/jmod bin/jhsdb bin/jps bin/jstack bin/jrunscript bin/javadoc bin/javap bin/jar bin/jaotc bin/javac bin/schemagen bin/jshell bin/xjc bin/rmic bin/jdeprscan bin/jimage bin/jstatd bin/jmap bin/jdb bin/serialver bin/wsgen bin/jcmd bin/jarsigner'
JDK_PATHS='bin/appletviewer bin/jconsole'
JINFO_FILENAME="$JVM_PATH/.$ALIAS.jinfo"

generate_jinfo_file() {
  echo "generando archivo $(basename $JINFO_FILENAME)"
  echo "name=$JAVA_DIRNAME" > $JINFO_FILENAME
  echo "alias=$ALIAS" >> $JINFO_FILENAME
  echo "priority=$PRIORITY" >> $JINFO_FILENAME
  echo "section=main\n" >> $JINFO_FILENAME

  for hl_path in $HL_PATHS; do
    hl_name=$(basename $hl_path)
    echo "hl $hl_name $JAVA_PATH/$hl_path" >> $JINFO_FILENAME
  done

  for jdkhl_path in $JDKHL_PATHS; do
    jdkhl_name=$(basename $jdkhl_path)
    echo "jdkhl $jdkhl_name $JAVA_PATH/$jdkhl_path" >> $JINFO_FILENAME
  done

  for jdk_path in $JDK_PATHS; do
    jdk_name=$(basename $jdk_path)
    echo "jdk $jdk_name $JAVA_PATH/$jdk_path" >> $JINFO_FILENAME
  done

  echo "plugin mozilla-javaplugin.so $JAVA_PATH/lib/IcedTeaPlugin.so" >> $JINFO_FILENAME
}

config_update_alternative() {
  ALTERNATIVE_PATH="$JAVA_PATH/$1"
  ACTION=$2
  NAME=$(basename $ALTERNATIVE_PATH)
  ACTION_PARAMS="$NAME $ALTERNATIVE_PATH"
  if [ "$ACTION" = "install" ]; then
    LINK="/usr/bin/$NAME"
    ACTION_PARAMS="$LINK $ACTION_PARAMS $PRIORITY"
  fi

  echo "update-alternatives $ACTION $NAME"
  update-alternatives --verbose "--$ACTION" $ACTION_PARAMS
  if [ "$ACTION" = "remove" ]; then
    update-alternatives --verbose --auto $NAME
  fi
}

config_update_alternatives() {
  ALL_PATHS="$HL_PATHS $JDKHL_PATHS $JDK_PATHS"

  for p in $ALL_PATHS; do
    if [ -f "$JAVA_PATH/$p" ]; then
      config_update_alternative $p $1
    fi
  done
}

install_alternative_java() {
  echo 'configurando update-alternatives'
  config_update_alternatives install
  echo "creando enlace simbolico $ALIAS -> $JAVA_PATH"
  ln -s "$JAVA_PATH" "$JVM_PATH/$ALIAS"
  generate_jinfo_file
}

remove_alternative_java() {
  echo 'desconfigurando update-alternatives'
  config_update_alternatives remove
  echo "eliminando enlace simbolico $ALIAS"
  rm "$JVM_PATH/$ALIAS"
  echo "eliminando archivo $(basename $JINFO_FILENAME)"
  rm "$JINFO_FILENAME"
}

case $1 in
  -i|--install)
    install_alternative_java
    ;;
  -r|--remove)
    remove_alternative_java
    ;;
  *)
    echo "Uso: $(basename $0) OPCIÓN JAVA_DIRNAME ALIAS [PRIORITY]"
    echo "OPCIÓN:"
    echo "  -i, --install"
    echo "  -r, --remove"
    echo
    exit 0
    ;;
esac
echo "Listo!"
