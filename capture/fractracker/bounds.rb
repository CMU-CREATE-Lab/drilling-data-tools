def split_bounds(bounds)
  ret = 4.times.map {bounds.clone}
  ret[0]["xmax"] = ret[1]["xmin"] = ret[2]["xmax"] = ret[3]["xmin"] = 0.5 * (bounds["xmin"] + bounds["xmax"])
  ret[0]["ymax"] = ret[1]["ymax"] = ret[2]["ymin"] = ret[3]["ymin"] = 0.5 * (bounds["ymin"] + bounds["ymax"])
  ret
end
