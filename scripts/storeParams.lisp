;set id
(eeprom-store-i 0 7)
;set

(def id (eeprom-read-i 0))

(if (= id 1) (progn
(def mvPerMm 16.094)
(def adcZero 1.657)
(def txId 0x10f0u32)
(def minPosMm 3)
(def maxPosMm 25)
(def actType 2)
))

(if (= id 2) (progn
(def mvPerMm 16.062)
(def adcZero 1.683)
(def txId 0x11f0u32)
(def minPosMm -41.0)
(def maxPosMm 41.0)
(def actType 1)
))

(if (= id 3) (progn
(def mvPerMm 16.096)
(def adcZero 1.674)
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
(def mvPerMm 15.953)
(def adcZero 1.690)
(def txId 0x10f0u32)
(def minPosMm 8.0)
(def maxPosMm 52.0)
(def actType 0)
))

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
(def maxPosMm 55.0)
(def actType 1)
))


(eeprom-store-i 1 actType)
(eeprom-store-i 2 txId)
(eeprom-store-f 3 mvPerMm)
(eeprom-store-f 4 adcZero)
(eeprom-store-f 5 minPosMm)
(eeprom-store-f 6 maxPosMm)

(print "All parameters stored")