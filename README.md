# NFL_Forecasting
 Machine Learning Model(s) to Predict NFL Game Winners, Point Spread and Over/Under Total

 ## Project Intro/Overview

This is a passion project that I have talked about pursuing for many years, but did not have the time. The purpose of this project is to develop Machine Learning Models to predict NFL outcomes. The intital concept, inspired by the [FiveThirtyEight Forecasting Game](https://projects.fivethirtyeight.com/2022-nfl-forecasting-game/), was a simple Logistic Regression to predict the winner and probability for each game of the 2022 NFL season. 

From there, the project expanded to predicting NFL Point Spreads and Over/Under lines. The initial models and data concepts where influenced by JP Wright's excellent [NFL Betting Market Analysis](https://github.com/jp-wright/nfl_betting_market_analysis).

The model was further enhanced by the integration of NFL Play-by-Play data courtesy of the amazing people at [NFLverse](https://github.com/nflverse)/[NFLfastR](https://www.nflfastr.com/index.html) and [Opensourcefootball](https://www.opensourcefootball.com/). 

## Data Sources

- FiveThirtyEight - [ELO](https://github.com/fivethirtyeight/data/tree/master/nfl-elo) 
- Football Outsiders - [DVOA](https://www.footballoutsiders.com/) 
- NFLverse - [Play-by-Play](https://github.com/nflverse/nflverse-pbp)
- Aussportbetting - [Historical Odds](https://www.aussportsbetting.com/data/)

## Model Iterations

- **V1/V1.5** - Logistic regression model to predict winner of game and probability
    - Primary data is ELO and DVOA
    - Explored XGBoost and alternative models but did not see much improvement over basic Logistic Regression
- **V2** - Bring in play-by-play data, specifically EPA data
    - Develop Linear regression models to predict Point Spreads and Over/Under lines
- **V2.5** - Add exponentially weighted moving average for each teams points scored to Over/Under model


## Current Model Performance
*Note: Model 2.5 was not fully deployed until week 9 of the 2022.*
### Logistic Regression
- Cross Validation Accuracy Score: 65.91
### Linear Regression - Point Spread
- K-folds Cross Valiation:
    - Mean Absolute Errors: 1.885
    - R-Squared: 0.83
### Linear Regression - Over/Under Total
- K-folds Cross Valiation:
    - Mean Absolute Errors: 1.86
    - R-Squared: 0.77

## Next Steps
1. Develop models for 1st and 2nd half points
2. Integrate more play-by-play data such as RedZone efficiency and turnovers
3. Develop models to predict win totals for next season

## Thank Yous
My success and accomplishments are only possible because of the previous, outstanding, data analytics work in this area:
- [FiveThirtyEight](https://github.com/fivethirtyeight) for the intial data and inspiration to get started
- [Football Outsiders](https://www.footballoutsiders.com/) for the DVOA metrics and excellent analysis
- [nflverse](https://github.com/nflverse)/[fastnflR](https://www.nflfastr.com/index.html) for the truely amazing play-by-play data (and [Lee Sharpe](https://twitter.com/LeeSharpeNFL) for unknowingly leading me to the data)
- [Ben Dominguez](https://twitter.com/bendominguez011)/[Open Source Football](https://www.opensourcefootball.com/) for guidance on how to utilize EPA data in python
- [Max Bolger's nflfastR Python Guide](https://github.com/maxbolger/nflfastR-Python-Tutorial) for helping to understand the play-by-play data and structure in python
- [JP Wright](https://github.com/jp-wright) for the doing excellent analysis on NFL betting/modeling ideas

