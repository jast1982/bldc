;set id
(eeprom-store-i 0 2)
;set

(def id (eeprom-read-i 0))
;parameters front 2024_01_09
(if (= id 1) (progn
(def mvPerMm 19.10)
(def adcZero 1.50)
(def txId 0x10f0u32)
(def minPosMm -11.00);-10.5
(def maxPosMm 42.00); 35.5
(def actType 2)
))
;parameters front rudder 2024_01_10
(if (= id 2) (progn
(def mvPerMm 16.06)
(def adcZero 1.739)
(def txId 0x11f0u32)
(def minPosMm -41.0)
(def maxPosMm 41.0)
(def actType 1)
))

(if (= id 3) (progn
(def mvPerMm 19.163)
(def adcZero 1.502)
(def txId 0x10f0u32)
(def minPosMm 8)
(def maxPosMm 52)
(def actType 0)
))

(if (= id 4) (progn
(def mvPerMm 16.090)
(def adcZero 1.669)
(def txId 0x11f0u32)
(def minPosMm -55.0)
(def maxPosMm 55.0)
(def actType 1)
))

(if (= id 5) (progn
(def mvPerMm 19.008)
(def adcZero 1.491)
(def txId 0x10f0u32)
(def minPosMm 8.0)
(def maxPosMm 51.0)
(def actType 0)
))
;left rudder
(if (= id 6) (progn
(def mvPerMm 16.075)
(def adcZero 1.676)
(def txId 0x11f0u32)
(def minPosMm -55.0)
(def maxPosMm 55.0)
(def actType 1)
))


(if (= id 7) (progn
(def mvPerMm 16.115)
(def adcZero 1.688)
(def txId 0x11f0u32)
(def minPosMm -55.0)
(def maxPosMm 72.0)
(def actType 1)
))

(if (= id 8) (progn
(def mvPerMm 16.094)
(def adcZero 1.657)
(def txId 0x10f0u32)
(def minPosMm 1) 
(def maxPosMm 24) 
(def actType 2)
))

;new motor
(if (= id 9) (progn
(def mvPerMm 19.217)
(def adcZero 1.496)
(def txId 0x11f0u32)
(def minPosMm -58)
(def maxPosMm 67)
(def actType 1)
))


(eeprom-store-i 1 actType)
(eeprom-store-i 2 txId)
(eeprom-store-f 3 mvPerMm)
(eeprom-store-f 4 adcZero)
(eeprom-store-f 5 minPosMm)
(eeprom-store-f 6 maxPosMm)

(print "All parameters stored")