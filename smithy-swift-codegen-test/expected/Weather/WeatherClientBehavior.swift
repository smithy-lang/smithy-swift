/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

public protocol WeatherClientBehavior {
     func getCity(input: GetCityInput, completion: (GetCityOutput) -> Void)
     func getCityImage(input: GetCityImageInput, completion: (GetCityImageOutput) -> Void)
     func getCurrentTime(input: GetCurrentTimeInput, completion: (GetCurrentTimeOutput) -> Void)
     func getForecast(input: GetForecastInput, completion: (GetForecastOutput) -> Void)
     func listCities(input: ListCitiesInput, completion: (ListCitiesOutput) -> Void)

 }
