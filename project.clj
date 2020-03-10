(defproject poddydodger "0.1.0-SNAPSHOT"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :license {:name "EPL-2.0 OR GPL-2.0-or-later WITH Classpath-exception-2.0"
            :url  "https://www.eclipse.org/legal/epl-2.0/"}
  :dependencies [[org.clojars.scsibug/feedparser-clj "0.4.0"]
                 [org.clojure/clojure "1.9.0"]
                 [org.jdom/jdom2 "2.0.6"]
                 [net.java.dev.rome/rome "1.0.0"]
                 [progress "1.0.2"]]

  :native-image {:name      "poddydodger" ;; name of output image, optional
                 :graal-bin "/Users/tees/Downloads/graalvm-ce-java11-20.0.0/Contents/Home/bin/native-image" ;; path to GraalVM home, optional
                 :opts     ["--report-unsupported-elements-at-runtime"
                            "--initialize-at-build-time"
                            "--allow-incomplete-classpath"
                            ;;avoid spawning build server
                            ;; "-H:+PrintAnalysisCallTree" ;; < for finding deps / things that are reflected.
                            "--no-server"
                            "-H:EnableURLProtocols=https"
                            "-H:ReflectionConfigurationFiles=reflect-config.json"]}
                           

                
  :plugins [[io.taylorwood/lein-native-image "0.3.1"]]

  :main ^:skip-aot poddydodger.core
  :target-path "target/%s"
  :profiles {:uberjar {:aot :all}})
