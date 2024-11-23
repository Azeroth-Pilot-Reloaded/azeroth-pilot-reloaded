# Lib: HereBeDragons

## [2.14.3-release-4-g42b9e1d](https://github.com/Nevcairiel/HereBeDragons/tree/42b9e1d91fbb7049bea8200f7c2107d0b37dfaa0) (2024-10-02)
[Full Changelog](https://github.com/Nevcairiel/HereBeDragons/compare/2.14.3-release...42b9e1d91fbb7049bea8200f7c2107d0b37dfaa0) [Previous Releases](https://github.com/Nevcairiel/HereBeDragons/releases)

- Update the zone information on a timer after the event fires  
    This should hopefully catch some edge-cases of zone information being  
    out of date in some areas.  
- Update TOC for the latest WoW updates  
- Add a migration step if a version with the old pin pool loaded beforehand  
- Support translating coordinates from the Isle of Dorn to the KhazAlgar continent map  
    This uses a manual override due to the maps being on different  
    instances, but sharing the same map. Only that one particular  
    combination with TranslateZoneCoordinates is supported.  
