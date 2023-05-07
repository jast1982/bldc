;these are the min/max positions in mm for this specific actuator. 
;Measure them by going at 5% speed to these position and read the currentposmm value. 
;Consider substracting 0.5mm safety buffer
;change these values and click on upload. The actuator will reinitialize and should no obey the limits

;calibration output from calib script
; calibration of the right actuator

(def id (eeprom-read-i 0))


(if (= id 0) (progn

(print "Error! No ID in eeprom found!")
(loopwhile t
        (progn
    (sleep 0.1)
))))

(print (str-from-n id "ID: %i"))

(def actType (eeprom-read-i 1))
(def txId (eeprom-read-i 2))
(def mvPerMm (eeprom-read-f 3))
(def adcZero (eeprom-read-f 4))
(def minPosMm (eeprom-read-f 5))
(def maxPosMm (eeprom-read-f 6))

(print (str-from-n actType "ActType: %i"))
(print (str-from-n txId "TxId: 0x%x"))
(print (str-from-n mvPerMm "mvPerMm: %3.2f"))
(print (str-from-n adcZero "adcZero: %3.2f"))
(print (str-from-n minPosMm "minPosMm: %3.2f"))
(print (str-from-n maxPosMm "maxPosMm: %3.2f"))


;this is the calculated value
(def degPerMm 202.5)
(def calibPoint 0.0)
(if (= actType 0) (def calibPoint 40.0))
(if (= actType 2) (def calibPoint 14.0))
(def adcCalibPoint (+ adcZero (/ (* calibPoint mvPerMm) 1000)))
(def rxId 0x20e0u32)
(set-servo-min-pos -10000000)
(set-servo-max-pos 10000000)
(set-servo-power 20 0)    
(def runway 147.5)
(def ctrlActive 0)
(def limitCnt 0)
(define #setPos 0)
(define #setSpeed 10)
(define #setFlags 0)  
(define data-out (array-create 8))
(define maxSpeed 35000)
(define lastControlActive 0)
(def lastFault 0)
(def faultCnt 0)
(def errorCodeOut 0)
(def lastFaultTime 0)
(def lastTime 0)
(def uiTimeout 0)
#init
;(lbm-set-quota 100)
(def #positionSensor (get-adc 3))
(def calibAdcValStart 0.9)
(def deltaT 0)


(defun error-stop (errorStr errorCode)
    (progn
    (print "Stopped due to error!")
    (print errorStr)
    (def errorCodeOut errorCode)
     (loopwhile t (progn
     
        (bufset-i16 data-out 0 0)
        (bufset-i16 data-out 2 0)
        (bufset-i16 data-out 4 0) ; 2.692 is the constant to convert to mm/s
       
        (bufset-u8 data-out 6 0) 
        (bufset-u8 data-out 7 errorCodeOut)
        (send-data data-out)
        (can-send-eid txId (list (bufget-u8 data-out 0) (bufget-u8 data-out 1) (bufget-u8 data-out 2) (bufget-u8 data-out 3) (bufget-u8 data-out 4) (bufget-u8 data-out 5) (bufget-u8 data-out 6) (bufget-u8 data-out 7) ))
        (sleep 0.01)
     ))
))



(def lastFault (get-fault))
;(if (!= lastFault 0) (error-stop "Motor controller fault detected" 3))
        

;go to the lower calibration point
(print "Going to actual calib point...")
  
(loopwhile t
        (progn
        (def currentPos (get-servo-pos))
        (def currentPosMm (/ currentPos degPerMm))
        (def currentIn (abs (get-current))) 
        (def #positionSensor (get-adc 3))
        
        (if (> #positionSensor adcCalibPoint) (set-servo-pos-speed -100000 1000) (set-servo-pos-speed 100000 1000))
        
        (if (> currentIn 40.0) (def limitCnt (+ limitCnt 1)) (def limitCnt 0))
        
        (if (> limitCnt 50) (error-stop "Hit current limit while going to calib point" 1))    
        (def lastFault (get-fault))
        (if (!= lastFault 0) (error-stop "Motor controller fault detected" 3))
        (if (< (abs (- #positionSensor adcCalibPoint)) 0.05) (break))
        (sleep 0.001)
        )
        
)

(set-handbrake 0.5)
(sleep 0.1)

(def #positionSensor (get-adc 3))
(def #posSense (/ (* (- #positionSensor adcZero) 1000) mvPerMm))
       
(reset-servo-pos (* #posSense degPerMm))
(set-servo-min-pos (* minPosMm degPerMm))
(set-servo-max-pos (* maxPosMm degPerMm))
(def currentPos (get-servo-pos))

(sleep 0.5)
;(if (= uiTimeout 0) (auto-range-test))

(set-servo-power 100 1)    
(print "Calibrated. Activating Control...")

(def currentPos (get-servo-pos))
(def currentPosMm (/ currentPos degPerMm))
(def #positionSensor (get-adc 3))
(def #posSense (/ (* (- #positionSensor adcZero) 1000) mvPerMm))
      
(def posDiff0 (abs (- #posSense currentPosMm)))
     
(def #setPos (* 2 degPerMm))
(def #setSpeed 20)
(def testState 0)
(def testCnt 0)
(def testValCnt 0)

(def testVal 0.0)
(def ctrlActive 1)
(loopwhile t (progn
    
        (def currentPos (get-servo-pos))
        (def currentPosMm (/ currentPos degPerMm))
        (def currentIn (abs (get-current-in))) 
        (def vbus (get-vin)) 
        (def rpm (get-rpm))
        (def #positionSensor (get-adc 3))
        
        (def deltaT (secs-since lastTime))
        (def lastTime (systime))
        
        (def #posSense (/ (* (- #positionSensor adcZero) 1000) mvPerMm))
        (def posDiff (abs (- #posSense currentPosMm posDiff0)))
        
        (bufset-i16 data-out 0 (* currentPosMm 100))
        (bufset-i16 data-out 2 (* currentIn vbus))
        (bufset-i16 data-out 4 (* #posSense 100)) ; 2.692 is the constant to convert to mm/s
       ; (bufset-i16 data-out 4 (* rpm 0.02962)) ; 2.692 is the constant to convert to mm/s
       
        (if (= ctrlActive 0) (bufset-u8 data-out 6 0xF0) (bufset-u8 data-out 6 0xF1))
        (bufset-u8 data-out 7 errorCodeOut)
       
        (def lastFault (get-fault))
        (if (and (!= lastFault 0) (!= lastFault 11)) (error-stop "Motor controller fault detected" 3)) 
        (if (< (abs currentPosMm) 15) (if (> posDiff 6.0) (error-stop "Position sensor difference detected" 2)))
         
        (if (= errorCodeOut 0) (if (= ctrlActive 1) (set-servo-pos-speed (/ (* #setPos degPerMm) 100) (/ (* maxSpeed #setSpeed) 100) ) (set-handbrake 0.5))
        )
        (def desPosDiff (abs (- #setPos currentPos)))
        (def testCnt (+ testCnt 1))
       
        (if (> testCnt 200) (progn
            (def testVal (+ testVal #positionSensor))
            (def testValCnt (+ testValCnt 1))
        ))
        (if (= testCnt 500) (progn
            (def testVal (/ testVal testValCnt))
            (print (str-from-n currentPosMm "Pos: %3.2f"))
            (print (str-from-n testVal "Val: %3.2f"))
            (def #setPos (+ #setPos (* 0.5 degPerMm)))

            (def testCnt 0)
            (def testState 0)
            (def testVal 0)
            (def testValCnt 0)
            (if (> currentPosMm maxPosMm) (progn
                (error-stop "Calibration done" 10)
            ))
        ))
        
        
        (sleep 0.001)
        
))

      ; (loopwhile t (progn (set-handbrake 0.5) (sleep 0.001))) 
                 