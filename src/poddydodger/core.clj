(ns poddydodger.core
  (:require [clojure.string :as string]
            [clojure.java.io :as io]
            [clojure.pprint :refer [pprint]]

            [progress.file :as progress]
            [feedparser-clj.core :as rss])
  (:gen-class))


(def config
  {:out-dir      "resources/tmp/"
   :feed         ""
   :episodes     []
   :num-episodes nil
   :curr-file    {:name  nil
                  :url   nil}})

(defn write-file-name
  [{:keys [out-dir]} ep-title]
  (str out-dir ep-title ".mp3"))

(defn file-exists?
  [file ep-title]
  (if (.exists (io/file file))
    (do
      (println "File: <" ep-title "> already exists.")
      (println "If you want to re-downoad it, you will need to delete the file manually. \n")
      true)
    false))

(defn download-uri
  "Takes url as input stread to file (with a progress bar.)"
  [cfg ep-title url]
  (let [file (write-file-name cfg ep-title)]
    (when-not (or (file-exists? file ep-title) (nil? url))
      (progress/with-file-progress file
        (with-open [in  (io/input-stream url)
                    out (io/output-stream file)]
          (print ep-title ":")
          (io/copy in out))))))

(defn get-episodes
  "Fetches episodes from an RSS feed and loops over them to download each."
  [{:keys [feed] :as cfg}]
  (let [fetch        (rss/parse-feed feed)
        eps          (fetch :entries)
        out-name     #(str (:out-dir config) % ".mp3")
        get-ep-url   #(-> % :enclosures first :url)
        get-ep-title #(-> % :title)
        cfg (assoc cfg :episodes eps :total-count (count eps))]

    (println "Downloading" (cfg :total-count) "episodes. This could take a while. \n")
    (doseq [ep   (take 2 eps)
            :let [url (-> ep :enclosures first :url)
                  ep-name (ep :title)]]
      (download-uri cfg (get-ep-title ep) (get-ep-url ep)))))
   


(defn -main
  ""
  [& args]
  (let [c (assoc config :feed (first args))]
    (get-episodes c)))

;; (get-episodes "https://www.omnycontent.com/d/playlist/aaea4e69-af51-495e-afc9-a9760146922b/2f221518-53f6-4aaa-b3eb-aa86015d7469/fa6139ac-7f87-4d72-98e1-aa86015d7477/podcast.rss"))

;; (-main "https://www.omnycontent.com/d/playlist/aaea4e69-af51-495e-afc9-a9760146922b/2f221518-53f6-4aaa-b3eb-aa86015d7469/fa6139ac-7f87-4d72-98e1-aa86015d7477/podcast.rss")


;; (->
;;  (rss/parse-feed "https://www.omnycontent.com/d/playlist/aaea4e69-af51-495e-afc9-a9760146922b/2f221518-53f6-4aaa-b3eb-aa86015d7469/fa6139ac-7f87-4d72-98e1-aa86015d7477/podcast.rss")
;;  (:entries)
;;  (count)
;;  )
