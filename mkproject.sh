
inject_dep() {
  org=$1
  name=$2
  rev=$3

  cat ivy/ivy.xml | \
    awk "/  <\/dependencies>/ { print \"    <dependency org=\\\"${org}\\\" name=\\\"${name}\\\" rev=\\\"${rev}\\\" /> <!--auto-->\" } { print }" \
        > ivy/ivy2.xml && \
    mv ivy/ivy2.xml ivy/ivy.xml
}

reset_dep() {
  cat ivy/ivy.xml | awk "!/<!--auto-->/ { print }" > ivy/ivy2.xml && mv ivy/ivy2.xml ivy/ivy.xml
}

echo
echo "Let's create a new scala project."
read -p "  package root (like 'com.example'): " -e package_root
read -p "  project name (like 'echod'): " -e project_name
read -p "  description for humans: " -e description
echo "  ----------"
read -p "  using thrift? [n]: " -e use_thrift
read -p "  using jmock? [n]: " -e use_jmock

test "x$package_root" = "x" && package_root="com.example"
test "x$project_name" = "x" && project_name="echod"
test "x$description" = "x" && description="sample project"
test "x$use_thrift" = "x" && use_thrift="n"
test "x$use_jmock" = "x" && use_jmock="n"
package_path=$(echo ${package_root} | sed -e 's/\./\//g')

echo
echo "Creating project ${package_root}.${project_name}"
reset_dep

cat ivy/ivy.xml | \
  sed -e "s/organisation=\".*\"/organisation=\"${package_root}\"/" \
      -e "s/module=\".*\"/module=\"${project_name}\"/" \
      -e "s/e:buildpackage=\".*\"/e:buildpackage=\"${package_root}.${project_name}\"/" \
      -e "s/e:testclass=\".*\"/e:testclass=\"${package_root}.${project_name}.TestRunner\"/" \
      -e "s/e:jarclassname=\".*\"/e:jarclassname=\"${package_root}.${project_name}.Main\"/" \
      -e "s/e:thriftpackage=\".*\"/e:thriftpackage=\"${package_root}.${project_name}.gen\"/" \
      > ivy/ivy2.xml && \
  mv ivy/ivy2.xml ivy/ivy.xml

cat build.xml | \
  sed -e "s/<project name=\".*\" default/<project name=\"${project_name}\" default/" \
      -e "s/<description>.*<\/description>/<description>${description}<\/description>/" \
      > build2.xml && \
  mv build2.xml build.xml

mkdir -p src/main/scala/${package_path}/${project_name}
mkdir -p src/test/scala/${package_path}/${project_name}
test $use_thrift = "n" || {
  mkdir -p src/test/thrift
  inject_dep thrift libthrift 20080411p1
}

# temporarily needed due to bug in specs:
inject_dep junit junit 4.4

test $use_jmock = "n" || {
  inject_dep org.jmock jmock 2.4.0
  inject_dep org.hamcrest hamcrest-all 1.1
  inject_dep cglib cglib 2.1_3
  inject_dep asm asm 1.5.3
  inject_dep objenesis objenesis 1.1
}

cat >src/main/scala/${package_path}/${project_name}/Main.scala <<__EOF__
package ${package_root}.${project_name}

object Main {
  def main(args: Array[String]) {
    println("Hello, world!")
  }
}
__EOF__

cat >src/test/scala/${package_path}/${project_name}/TestRunner.scala <<__EOF__
package ${package_root}.${project_name}

import org.specs.runner.SpecsFileRunner

object TestRunner extends SpecsFileRunner("src/test/scala/**/*.scala", ".*",
  System.getProperty("system", ".*"), System.getProperty("example", ".*"))
__EOF__

echo "Done."
echo

# <!--dependency org="org.mockito" name="mockito-core" rev="1.7" conf="test->*"/-->
