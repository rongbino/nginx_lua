#!/bin/sh

GIT_REPOSITORY=http://github.com/passport/sogou-passport.git
GIT_HOME=/search/build/passport.git-deploment
BUILD_HOME=/search/build/passport.build-deploment

BRANCH=master

if [ ! -d "/search/build" ];then
        mkdir /search/build
fi

if [ ! -d "$GIT_HOME" ];then
        mkdir $GIT_HOME
fi

if [ ! -d "$BUILD_HOME" ];then
        mkdir $BUILD_HOME
fi

NUMBER=$#
i=1
while [[ $i -le $NUMBER ]]
do                        #将数组a[i]赋值为$1,即取得到第一个参数并将值存入a[1]
        if [[ $1  = "-b" ]]; then
                ((i++))                       #数组后移一位,变为a[2]
                shift
                NUMBER=$NUMBER-1                    #使用shift命令将参数后移一位,即此时的$1为第二个参数
                BRANCH=$1
            fi:q
        ((i++))                       #数组后移一位,变为a[2]
        shift                     #使用shift命令将参数后移一位,即此时的$1为第二个参数
done

echo '部署分支:'${BRANCH}

sleep 1

# update git & copy to build_home
rm -rf $GIT_HOME
git clone $GIT_REPOSITORY $GIT_HOME
cd $GIT_HOME
git fetch
git checkout -b $BRANCH origin/$BRANCH
read old_hits <<< git show | head -1 | awk '{print $2}'
rsync -az --delete $GIT_HOME/* $BUILD_HOME/

# mvn build
cd $BUILD_HOME
MVN=/usr/local/maven/bin/mvn
$MVN clean install -Dmaven.test.skip=true -Pprod -s /search/pre_deploy_script/deploment/settings.xml
#$MVN clean install -Dmaven.test.skip=true -Pdev -s /search/pre_deploy_script/deploment/settings.xml

WORK_DIR=/search/jetty/webapps

mv -f passport-main-web/target/passport-main-web.war $WORK_DIR/ROOT.war
/usr/local/jetty/bin/jetty.sh restart

rm -rf $GIT_HOME
rm -rf $BUILD_HOME
