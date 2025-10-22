#!/bin/bash

rm -rf ./publish
dotnet publish -c Release -o ./publish ./src/aspnet/UserUpload.csproj
(cd ./publish && zip -r ../app1.zip .)