#' Get Google Books Ngram Data By Group
#'
#' This function fetches the underlying plot data for Google Books Ngrams for a sequence of related terms.
#'
#' @param terms Terms to query against the Google Books corpus. Typically a vector.
#' @param qualifiers A set of terms, typically qualifiersectives, that will precede each element in `terms`.
#' @param yr.start The first year to query. Defaults to 1800.
#' @param yr.end The last year to query. Defaults to 2008.
#' @param group.by Whether to group results by `terms` (1) or `qualifiers` (2). Defaults to 1.
#' @param include.all.cases Boolean that indicates whether to query each term twice, once with first letter capitalized and once with it uncapitalized. Defaults to FALSE.
#' @param include.plurals Boolean that indicates whether to also include naive plurals in the query terms. Defaults to FALSE. If TRUE, expands `terms` to also include a duplicate of each element, but with an `s` added.
#' @param smoothing The number of years to smooth over. Defaults to 0.
#' @param data.path The path to save data to. Defaults to current working directory.
#' @param f.overwrite Boolean that captures whether to overwrite save files. Useful if you use the same terms, but change the year range. Defaults to FALSE.
#' @param save.data Boolean that captures whether to save data to disk. Defaults to FALSE If searching/analysing a large number of terms, this will save a lot of time.
#' @param corpus The corpus to query. Defaults to 15, which corresponds to the English language corpus.
#' @param verbose Boolean that indicates whether to print internal messages. Defaults to FALSE.
#' @keywords ngrams
#' @export ngram_group
#' @examples
#' library(ggplot2)
#' library(tidyr)
#' library(dplyr)
#'
#' # set query terms
#' main.terms <- c("soldier", "politician", "writer")
#' adjs <- c("British", "English")
#'
#' # plot by term
#' df <- ngram_group(main.terms, adjs, include.plurals = TRUE)
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
#'
#'
#' # group by qualifier
#' df <- ngram_group(main.terms, adjs, group.by = 2,
#'                            include.plurals = TRUE)
#'
#' df.plot <- df %>%
#'  gather(term, frequency, -year)
#'
#' p <- ggplot(df.plot, aes(year, frequency, colour=term)) + geom_line() +
#'  ylab("Frequency") +
#'   xlab("Year") +
#'   ggtitle("Terms in Google Books, 1800-2000") +
#'   theme_bw()
#' p

ngram_group <- function(terms,
                                 qualifiers,
                                 yr.start = 1800,
                                 yr.end = 2000,
                                 group.by = 1,
                                 smoothing = 0,
                                 include.plurals = F,
                                 include.all.cases = F,
                                 save.data = F,
                                 data.path = NULL,
                                 f.overwrite = F,
                                 corpus = 15,
                                 verbose = F) {

  prefix <- function(str, terms){
    return(sapply(terms, function(x) {paste(str, x)}))
  }

  plural <- function(terms){
    return(sapply(terms, function(x) {paste0(x, "s")}))
  }

  capFirstLetter <- function( str ){
    return(paste0(toupper(substr(str, 1, 1)), substr(str, 2, nchar(str))))
  }

  unCapFirstLetter <- function( str ){
    return(paste0(tolower(substr(str, 1, 1)), substr(str, 2, nchar(str))))
  }

  capitalize <- function( vec ) {
    return(sapply(vec, function( x ) { capFirstLetter( x ) } ))
  }

  uncapitalize <- function( vec ) {
    return(sapply(vec, function( x ) { unCapFirstLetter( x ) } ))
  }


  #
  # start function
  #

  if(is.null( data.path )){
    data.path <- paste0( getwd(), "/" )
  }

  if(group.by == 1){

    for(i in 1:length( terms )){


      f.path <- paste0( data.path, "gb-ngram-", terms[i], ".RData" )

      if(!(file.exists( f.path )) || f.overwrite == T){
        if(!(is.null( qualifiers ))){
          q <- qualifiers
          if(include.all.cases == T){
              q <- c(capitalize(q), uncapitalize(q))
          }
          q <- prefix( q, terms[i] )
        } else {
          if(include.all.cases == T){
            q <- c(capitalize( terms[i] ), uncapitalize( terms[i] ))
          } else {
            q <- terms[i]
          }
        }

        if(include.plurals == T){
          q <- c( q, plural( q ) )
        } else {
          q <- q
        }

        if(verbose == T){
          cat("\nSearching for the following terms in Google Books: \n")
          print(as.character(q))
        }

        df.query <- ngram( q, yr.start, yr.end, smoothing, corpus, verbose )
        if(save.data == T){
          saveRDS( df.query, file = f.path )
        }
      } else {
        df.query <- readRDS( f.path )
      }

      q.vec <- apply(dplyr::select( df.query, -year ), 1, function(x) { sum( x ) } )
      df <- data.frame( q.vec, df.query$year )

      if(!(is.null( qualifiers ))){
        names( df ) <- c( paste( qualifiers[1], terms[i]), "year" )
      } else {
        names( df ) <- c( terms[i], "year" )
      }

      if(i == 1){  df.master <- df } else {
        df.master <- merge( df.master, df, by = "year" )
      }
    }
  }

  if(group.by == 2){
    for(i in 1:length( qualifiers )){

      f.path <- paste0( data.path, "gb-ngram-", qualifiers[i], ".RData" )

      if(!(file.exists( f.path )) || f.overwrite == T){
        q <- prefix( qualifiers[i], terms)

        if(include.all.cases == T){
          q <- c(capitalize(q), uncapitalize(q))
        }

        if(include.plurals == T){
          q <- c( q, plural( q ) )
        } else {
          q <- q
        }

        if(verbose == T){
          cat("\nSearching for the following terms in Google Books: \n")
          print(as.character(q))
        }

        df.query <- ngram( q, yr.start, yr.end, smoothing, corpus, verbose )
        if(save.data == T){
          saveRDS( df.query, file = f.path )
        }
      } else {
        df.query <- readRDS( f.path )
      }

      q.vec <- apply(dplyr::select( df.query, -year ), 1, function(x) { sum( x ) } )
      df <- data.frame( q.vec, df.query$year )

      names( df ) <- c( qualifiers[i], "year" )

      if(i == 1){  df.master <- df } else {
        df.master <- merge( df.master, df, by = "year" )
      }
    }
  }

  return( df.master )
}
