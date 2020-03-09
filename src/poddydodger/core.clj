(ns poddydodger.core
  (:require [clojure.string :as string]
            [clojure.java.io :as io]
            [feedparser-clj.core :as rss])
  (:gen-class))

(def out-dir "resources/tmp/")
(def config
  {:out-dir "resources/tmp/"})



(defn out-name
  [n]
  (str out-dir n))

(defn make-output
  []
  nil)

(defn download-uri
  [uri file]
  (prn "URI is " uri)
  (when-not ( nil? uri)
    (with-open [in (io/input-stream uri)
                out (io/output-stream file)]
      (io/copy in out))))


(defn get-episodes
  [feed-url]
  (let [fetch    (rss/parse-feed feed-url)
        eps      (fetch :entries)
        out-name #(str (:out-dir config) % ".mp3")] ;; FIXME auto get audio file type. Can't assume mp3.


    (prn "Downloading episodes. This could take a while.")
    (doseq [e    (take 2 eps)
            :let [dl-link (-> e :enclosures first :url) ;; FIXME: handle enclosure is not mp3. ;; FIXME - some use URI, some use URL
                  ep-name (e :title)]]

      (prn "Episode: " (:title e))
      (download-uri dl-link  (out-name ep-name)))
    eps))


(defn -main
  ""
  [& args]
  ;; (get-episodes "https://www.dancarlin.com/dchh-feedburner.xml")
  (get-episodes "https://www.omnycontent.com/d/playlist/aaea4e69-af51-495e-afc9-a9760146922b/2f221518-53f6-4aaa-b3eb-aa86015d7469/fa6139ac-7f87-4d72-98e1-aa86015d7477/podcast.rss"))

;; (rss/parse-feed "https://www.omnycontent.com/d/playlist/aaea4e69-af51-495e-afc9-a9760146922b/2f221518-53f6-4aaa-b3eb-aa86015d7469/fa6139ac-7f87-4d72-98e1-aa86015d7477/podcast.rss")

(-main)
