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
(def #positionSensor (get-adc 0))
(def calibAdcValStart 0.9)
(def deltaT 0)
(def triggerCalib 0)
(def powerTest 0)

(defun proc-eid (id data)
        (if (= uiTimeout 0)
        (progn
      ;  (print (buflen data))
         (if (= actType 1) (define #setPos (bufget-i16 data 2)) (define #setPos (bufget-i16 data 0)))
        (define #setSpeed (bufget-u8 data 6))
        (define #setFlags (bufget-u8 data 7))
        
        
        (if (= #setFlags 0) 
                (progn
                (if (= ctrlActive 1) (def triggerCalib 1))
                (define ctrlActive 0)
                )
                 (define ctrlActive 1))
       ; (print "pos:" #setPos #setSpeed #setFlags)
)))

; This is received from the QML-program which acts as a remote control for the robot
(defun proc-data (data)
    (progn    
    (define #setFlags (bufget-u8 data 7))
    
    (if (and (= #setFlags 8) (= powerTest 0)) (def powerTest 1))
    (if (and (= #setFlags 0) (= powerTest 2)) (def powerTest 0))
     
    (if (!= #setFlags 0) (progn
        (define #setPos (bufget-i16 data 0))
        (define #setSpeed (bufget-u8 data 6))
        (def uiTimeout 100)
          (define ctrlActive 1))
         ;else
         (progn
        ; (if (= ctrlActive 1) (def triggerCalib 1))
         (define ctrlActive 0)
                
         ))
       ; (print "pos:" #setPos #setSpeed #setFlags)
        )
     
  )

(defun auto-power-test ()
    (progn
    (print "Slowly moving to mininum limit")

    
(set-servo-power 100 0)
(def desPos 55)

 (loopwhile t (progn
        (def currentPos (get-servo-pos))
        (def currentPosMm (/ currentPos degPerMm))
        (def vbus (get-vin)) 
        (def currentIn (abs (get-current))) 
        (def rpm (get-rpm))
     

        (bufset-i16 data-out 0 (* currentPosMm 100))
        (bufset-i16 data-out 2 (* currentIn vbus))
        (bufset-i16 data-out 4 (* rpm 0.02962)) ; 2.692 is the constant to convert to mm/s
       
        (bufset-u8 data-out 6 0x80) 
        (bufset-u8 data-out 7 errorCodeOut)
        (send-data data-out)
        (can-send-eid txId (list (bufget-u8 data-out 0) (bufget-u8 data-out 1) (bufget-u8 data-out 2) (bufget-u8 data-out 3) (bufget-u8 data-out 4) (bufget-u8 data-out 5) (bufget-u8 data-out 6) (bufget-u8 data-out 7) ))
        (if (!= lastFault 0) (error-stop "Motor controller fault detected" 3))
        
        (set-servo-pos-speed (* desPos degPerMm) maxSpeed)
        (def pdiff (abs (- currentPosMm desPos)))
        (if (< pdiff 0.4) (break))
        (sleep 0.01)
     ))
(sleep 0.3)

      (def desPos 72)

 (loopwhile t (progn
        (def currentPos (get-servo-pos))
        (def currentPosMm (/ currentPos degPerMm))
        (def vbus (get-vin)) 
        (def currentIn (abs (get-current))) 
        (def rpm (get-rpm))
     

        (bufset-i16 data-out 0 (* currentPosMm 100))
        (bufset-i16 data-out 2 (* currentIn vbus))
        (bufset-i16 data-out 4 (* rpm 0.02962)) ; 2.692 is the constant to convert to mm/s
       
        (bufset-u8 data-out 6 0x80) 
        (bufset-u8 data-out 7 errorCodeOut)
        (send-data data-out)
        (can-send-eid txId (list (bufget-u8 data-out 0) (bufget-u8 data-out 1) (bufget-u8 data-out 2) (bufget-u8 data-out 3) (bufget-u8 data-out 4) (bufget-u8 data-out 5) (bufget-u8 data-out 6) (bufget-u8 data-out 7) ))
        (if (!= lastFault 0) (error-stop "Motor controller fault detected" 3))
        
        (set-servo-pos-speed (* desPos degPerMm) maxSpeed)
        (def pdiff (abs (- currentPosMm desPos)))
        (if (< pdiff 0.4) (break))
        (sleep 0.01)
     ))      
   
    (sleep 0.3)
 
(set-servo-power 30 0)

 (print "Faster moving to 0")

     (loopwhile t (progn
        (def currentPos (get-servo-pos))
        (def currentPosMm (/ currentPos degPerMm))
        (def vbus (get-vin)) 
        (def rpm (get-rpm))
        (def currentIn (abs (get-current))) 
     
        (bufset-i16 data-out 0 (* currentPosMm 100))
        (bufset-i16 data-out 2 (* currentIn vbus))
        (bufset-i16 data-out 4 (* rpm 0.02962)) ; 2.692 is the constant to convert to mm/s
       
        (bufset-u8 data-out 6 0xC0) 
        (bufset-u8 data-out 7 errorCodeOut)
        (send-data data-out)
        (can-send-eid txId (list (bufget-u8 data-out 0) (bufget-u8 data-out 1) (bufget-u8 data-out 2) (bufget-u8 data-out 3) (bufget-u8 data-out 4) (bufget-u8 data-out 5) (bufget-u8 data-out 6) (bufget-u8 data-out 7) ))
        (if (!= lastFault 0) (error-stop "Motor controller fault detected" 3))
       
        (set-servo-pos-speed 0 2000)
        (def pdiff (abs currentPosMm))
        (if (< pdiff 0.2) (break))
        (sleep 0.01)
     ))
     
    (def powerTest 2)

    )
)

(defun event-handler ()
    (loopwhile t
        (recv
            ((event-can-eid (? id) . (? data)) (proc-eid id data))
            ((event-data-rx ? data) (proc-data data))
            (_ nil) ; Ignore other events
)))

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

(event-register-handler (spawn event-handler))
(event-enable 'event-data-rx)
(event-enable 'event-can-eid)


(defun calibrate ()
    (progn

(def lastFault (get-fault))
;(if (!= lastFault 0) (error-stop "Motor controller fault detected" 3))
        (set-servo-power 40 0)


;go to the lower calibration point
(print "Going to actual calib point...")
  
(loopwhile t
        (progn
        (def currentPos (get-servo-pos))
        (def currentPosMm (/ currentPos degPerMm))
        (def currentIn (abs (get-current))) 
        (def #positionSensor (get-adc 0))
        
        (if (> #positionSensor adcCalibPoint) (set-servo-pos-speed -100000 1000) (set-servo-pos-speed 100000 1000))
        
        (if (> currentIn 40.0) (def limitCnt (+ limitCnt 1)) (def limitCnt 0))
        
        (if (> limitCnt 50) (error-stop "Hit current limit while going to calib point" 1))    
        (def lastFault (get-fault))
        (if (and (!= lastFault 0) (!= lastFault 11)) (error-stop "Motor controller fault detected" 3))
        (if (< (abs (- #positionSensor adcCalibPoint)) 0.05) (break))
        (sleep 0.001)
        )
        
)

(set-handbrake 0.5)
(sleep 2.0)
(def calibValueCnt 0)
(def calibCnt 0)
(def calibValue 0.0)
(loopwhile t
        (progn

        (def calibCnt (+ calibcnt 1))
        (set-handbrake 0.5)

        (if (> calibCnt 100) (progn
            (def #positionSensor (get-adc 0))

            (def #posSense (/ (* (- #positionSensor adcZero) 1000) mvPerMm))
            
            (def calibValue (+ calibValue #posSense))
            (def calibValueCnt (+ calibValueCnt 1))
        
        ))
        
        (if (> calibCnt 400) (break))
        (sleep 0.01)
        )
 )
 
(def calibValue (/ calibValue calibValueCnt))

(def #positionSensor (get-adc 0))
(def #posSense (/ (* (- #positionSensor calibValue) 1000) mvPerMm))
       
(reset-servo-pos (* calibValue degPerMm))
(set-servo-min-pos (* minPosMm degPerMm))
(set-servo-max-pos (* maxPosMm degPerMm))
(def currentPos (get-servo-pos))

(sleep 0.5)
;(if (= uiTimeout 0) (auto-range-test))

(set-servo-power 100 1)    
(print "Calibrated. Activating Control...")

(def currentPos (get-servo-pos))
(def currentPosMm (/ currentPos degPerMm))
 
(def posDiff0 (- currentPosMm calibValue))

(print (str-from-n currentPosMm "currentPosMm: %f"))
(print (str-from-n calibValue "calibValue: %f"))

(print (str-from-n posDiff0 "PosDiff: %f"))

)
)


(calibrate)
(loopwhile t (progn
    
        (if (= powerTest 1) (auto-power-test))
        
        (def currentPos (get-servo-pos))
        (def currentPosMm (/ currentPos degPerMm))
        (def currentIn (abs (get-current))) 
        (def vbus (get-vin)) 
        (def rpm (get-rpm))
        (def #positionSensor (get-adc 0))
        
        (def deltaT (secs-since lastTime))
        (def lastTime (systime))
        
        (def #posSense (/ (* (- #positionSensor adcZero) 1000) mvPerMm))
        (def posDiff (- (abs (- #posSense currentPosMm) ) posDiff0))
        
        (bufset-i16 data-out 0 (* currentPosMm 100))
        (bufset-i16 data-out 2 currentIn)
      ;  (bufset-i16 data-out 2 (* currentIn vbus))
;        (bufset-i16 data-out 4 (* rpm 0.02962)) ; 2.692 is the constant to convert to mm/s
        (bufset-i16 data-out 4 (* #posSense 100)) ; 2.692 is the constant to convert to mm/s
        (def faults (get-encoder-faults))
        (def lastFault (get-fault))
        (if (= ctrlActive 0) (bufset-u8 data-out 6 0x00) (bufset-u8 data-out 6 0xFF))
        (if (> faults 0) (bufset-u8 data-out 6 faults))
        (bufset-u8 data-out 7 lastfault)
       
        (if (> uiTimeout 0) (def uiTimeout (- uiTimeout 1)))
        
        (if (and (!= lastFault 0) (!= lastFault 11) (!= lastFault 4)) (error-stop "Motor controller fault detected" 3)) 
        ;(if (< (abs currentPosMm) 15) (if (> posDiff 6.0) (error-stop "Position sensor difference detected" 2)))
        (send-data data-out)
        (can-send-eid txId (list (bufget-u8 data-out 0) (bufget-u8 data-out 1) (bufget-u8 data-out 2) (bufget-u8 data-out 3) (bufget-u8 data-out 4) (bufget-u8 data-out 5) (bufget-u8 data-out 6) (bufget-u8 data-out 7) ))
        
        (if (= errorCodeOut 0) (if (= ctrlActive 1) (set-servo-pos-speed (/ (* #setPos degPerMm) 100) (/ (* maxSpeed #setSpeed) 100) ) (set-handbrake 0.5))
        )
    
        (if (= triggerCalib 1) (progn
            (def triggerCalib 0)
            (calibrate)
        ))
        
        
        (sleep 0.001)
        
))

      ; (loopwhile t (progn (set-handbrake 0.5) (sleep 0.001))) 
                 