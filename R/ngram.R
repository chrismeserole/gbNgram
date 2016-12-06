#' Get Google Books Ngram Data
#'
#' This function fetches the underlying plot data for Google Books Ngrams. It returns a dataframe with the frequency of each term for each year within a specified range.
#'
#' @param terms Terms to query against the Google Books corpus. Typically a vector.
#' @param yr.start The first year to query. Defaults to 1800.
#' @param yr.end The last year to query. Defaults to 2008.
#' @param smoothing The number of years to smooth over. Defaults to 0.
#' @param corpus The corpus to query. Defaults to 15, which corresponds to the English language corpus.
#' @param verbose Boolean that indicates whether to print internal messages.
#' @keywords ngrams
#' @examples
#'
#' library(ggplot2)
#' library(tidyr)
#' library(dplyr)
#'
#' # set query terms
#' main.terms <- c("soldier", "politician", "writer")
#'
#' # plot by term
#' df <- ngram(main.terms)
#'
#' df.plot <- df %>%
#'   gather(term, frequency, -year)
#'
#' p <- ggplot(df.plot, aes(year, frequency, colour=term)) + geom_line() +
#'   ylab("Frequency") +
#'   xlab("Year") +
#'   ggtitle("Terms in Google Books, 1800-2000") +
#'   theme_bw()
#' p

ngram <- function(terms,
                  yr.start = 1800,
                  yr.end = 2000,
                  smoothing = 0,
                  corpus = 15,
                  verbose = F){

  base.url <- "https://books.google.com/ngrams/graph?content="
  terms.encoded <- gsub(" ", "%20", terms)

  url <- paste(base.url,
               paste(c(paste(terms.encoded, collapse = "%2C"),
                       paste("year_start", yr.start, sep="="),
                       paste("year_end", yr.end, sep="="),
                       paste("smoothing", smoothing, sep="="),
                       paste("corpus", corpus, sep="=")),
                     collapse="&"), sep="")


  # get page source
  my.data.txt <- readLines(url)

  data.string <- my.data.txt[which(grepl("var data", my.data.txt))]

  # get variable names
  var.names <- strsplit(data.string, "\\\"ngram\\\": \\\"")[[1]]
  for(i in 2:length(var.names)){
    var.names[i] <- strsplit(var.names[i], "\\\"")[[1]][1]
  }
  var.names <- var.names[2:length(var.names)]
  n.cols <- length(var.names)

  if(length(terms) > length(var.names)){
    missing.terms <- terms[!(terms %in% var.names)]
    if(verbose == T){
      cat("\nThe following terms never appear in Google books: \n")
      print(as.character(missing.terms))
    }
  }

  # get ngram data
  data.array <- strsplit(data.string, ": \\[")[[1]]
  for(i in 2:length(data.array)){
    data.array[i] <- strsplit(data.array[i], "],")[[1]][1]
    df.obj <- as.numeric(unlist(strsplit(data.array[i], ", ")))

    if(i == 2){
      n.rows <- length(df.obj)
      df.ngram <- data.frame(matrix(NA, nrow = n.rows, ncol = n.cols))
    }

    df.ngram[[i-1]] <- df.obj

  }
  names(df.ngram) <- var.names

  df.ngram$year <- seq(yr.start, yr.end, 1)

  if(exists("missing.terms")){

    df.missing <- data.frame(matrix(0, nrow = n.rows, ncol = length(missing.terms)))
    names(df.missing) <- missing.terms

    df.ngram <- data.frame(cbind(df.ngram, df.missing))
    names(df.ngram) <- c(var.names, "year", missing.terms)

    df.ngram <- df.ngram[c(terms, "year")]
  }

  return(df.ngram)
}
