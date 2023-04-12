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
(if (= actType 1) (def calibPoint 0.0) (def calibPoint 40.0))
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
#init

(def #positionSensor (get-adc 3))
(def calibAdcValStart 0.9)



(defun proc-eid (id data)
        (if (= id 0xe020)
        (progn
      ;  (print (buflen data))
        (define #setPos (bufget-i16 data (* actType 2)))
        (define #setSpeed (bufget-u8 data 6))
        (define #setFlags (bufget-u8 data 7))
        
        
        (if (= #setFlags 0) (define ctrlActive 0) (define ctrlActive 1))
       ; (print "pos:" #setPos #setSpeed #setFlags)
)))

; This is received from the QML-program which acts as a remote control for the robot
(defun proc-data (data)
    (progn
        (define #setPos (bufget-i16 data 0))
        (define #setSpeed (bufget-u8 data 6))
        (define #setFlags (bufget-u8 data 7))
        
        (if (= #setFlags 0) (define ctrlActive 0) (define ctrlActive 1))
       ; (print "pos:" #setPos #setSpeed #setFlags)
        
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
    (loopwhile t (sleep 1.0))
    
))

(event-register-handler (spawn event-handler))
;(event-enable 'event-data-rx)
(event-enable 'event-can-eid)

(def lastFault (get-fault))
(if (!= lastFault 0) (error-stop "Motor controller fault detected" 3))
        

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

(set-servo-power 100 1)    
(print "Calibrated. Activating Control...")

(def currentPos (get-servo-pos))
(def currentPosMm (/ currentPos degPerMm))
(def #positionSensor (get-adc 3))
(def #posSense (/ (* (- #positionSensor adcZero) 1000) mvPerMm))
      
(def posDiff0 (abs (- #posSense currentPosMm)))
      

(loopwhile t (progn
    
        (def currentPos (get-servo-pos))
        (def currentPosMm (/ currentPos degPerMm))
        (def currentIn (abs (get-current-in))) 
        (def vbus (get-vin)) 
        (def rpm (get-rpm))
        (def #positionSensor (get-adc 3))
        
        
        (def #posSense (/ (* (- #positionSensor adcZero) 1000) mvPerMm))
        (def posDiff (abs (- #posSense currentPosMm posDiff0)))
        
        (bufset-i16 data-out 0 (* currentPosMm 100))
        (bufset-i16 data-out 2 (* currentIn vbus))
        (bufset-i16 data-out 4 (* rpm 0.02962)) ; 2.692 is the constant to convert to mm/s
       
        (if (= ctrlActive 0) (bufset-u8 data-out 6 0) (bufset-u8 data-out 6 1))
        (bufset-u8 data-out 7 errorCodeOut)
        
        ;(if (and (!= (get-fault) lastFault) (!= (get-fault) 0)) (progn 
        ;    (def faultCnt (+ faultCnt 1))
        ;    (def lastFaultTime (systime))
        ;))
        
        (if (> (systime) (+ lastFaultTime 10000)) (def faultCnt 0))
        
        (def lastFault (get-fault))
        (if (!= lastFault 0) (error-stop "Motor controller fault detected" 3))
        
        ;(if (> faultCnt 3) (error-stop "Motor controller fault detected" 3))
        
        (if (< (abs currentPosMm) 15) (if (> posDiff 6.0) (error-stop "Position sensor difference detected" 2)))
        (send-data data-out)
        (can-send-eid txId (list (bufget-u8 data-out 0) (bufget-u8 data-out 1) (bufget-u8 data-out 2) (bufget-u8 data-out 3) (bufget-u8 data-out 4) (bufget-u8 data-out 5) (bufget-u8 data-out 6) (bufget-u8 data-out 7) ))
        
        (if (= ctrlActive 1) (set-servo-pos-speed (/ (* #setPos degPerMm) 100) (/ (* maxSpeed #setSpeed) 100) ) (set-handbrake 0.5))
       
    
        
        (if (!= lastControlActive ctrlActive) (sleep 0.3) (sleep 0.01))
        (define lastControlActive ctrlActive)
        
))

      ; (loopwhile t (progn (set-handbrake 0.5) (sleep 0.001))) 
                 