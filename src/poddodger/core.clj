;; (set! *warn-on-reflection* true)

(ns poddodger.core
  (:require [clojure.java.io :as io]
            [clojure.string :as string]
            #_[feedparser-clj.core :as rss]
            [poddodger.feed-parser :as rss])

  (:gen-class))

(def config
  {:out-dir      "resources/tmp/"
   :feed         ""
   :episodes     []
   :num-episodes nil
   :curr-file    {:name  nil
                  :url   nil}})

(defn setup
  "Make directory at config out-dir"
  [^String path]
  (.mkdir (java.io.File. path)))


(defn write-file-name
  [{:keys [out-dir]} ep-title]
  (str out-dir ep-title ".mp3"))

(defn file-exists?
  [file ep-title]
  (if (.exists (io/file file))
    (do
      (println "File: <" ep-title "> already exists.")
      (println "If you want to re-download it, you will need to delete the file manually. \n")
      true)
    false))

(defn get-rss-feed!
  [rss-feed]

  (println "Trying to fetch rss feed!")
  (try
    (rss/parse-feed rss-feed)
    (catch
        Exception e (println "Error! RSS Feed may not be valid. Could not download any podcasts." e)
        (System/exit 1))))

(defn download-uri
  "Takes url as input stread to file (with a progress bar.)"
  [cfg ep-title url]
  (let [file (write-file-name cfg ep-title)]
    (when-not (or (file-exists? file ep-title) (nil? url))
      ;; (progress/with-file-progress file
      (with-open [in  (io/input-stream url)
                  out (io/output-stream file)]
        (println "Downloading " ep-title)
        (io/copy in out)))))

(defn get-episodes
  "Fetches episodes from an RSS feed and loops over them to download each."
  [{:keys [feed] :as cfg}]
  (let [fetch        (get-rss-feed! feed)
        eps          (get fetch :entries)
        cfg          (assoc cfg :episodes eps :total-count (count eps))]

    (println "Downloading" (cfg :total-count) "episodes. This could take a while. \n")
    (doseq [ep   eps
            :let [url     (-> ep (:enclosures) (first) (:url))
                  ep-name (:title ep)]]
      (download-uri cfg ep-name url))))

(defn -main
  ""
  [& args]
  (let [c (assoc config :feed (first args))]
    (setup (config :out-dir))
    (get-episodes c)))

