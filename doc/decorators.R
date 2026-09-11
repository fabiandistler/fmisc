## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=FALSE---------------------------------------------------------------
# fast <- with_cache(slow, .max_size = 1024, .ttl = 3600)

## ----eval=FALSE---------------------------------------------------------------
# memo <- memoise::memoise(slow, cache = cachem::cache_disk("~/.cache"))

## ----eval=FALSE---------------------------------------------------------------
# request("https://api.example.com") |>
#   req_throttle(rate = 10 / 1) |>
#   req_perform()

## -----------------------------------------------------------------------------
f <- function(x) x + 1
g <- f |>
  fmisc::with_retry(max_tries = 3L, backoff = 0) |>
  fmisc::with_timing(.report = "attribute")
print(g)

## -----------------------------------------------------------------------------
identical(fmisc::undecorate(g, depth = Inf), f)

