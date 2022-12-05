;these are the min/max positions in mm for this specific actuator. 
;Measure them by going at 5% speed to these position and read the currentposmm value. 
;Consider substracting 0.5mm safety buffer
;change these values and click on upload. The actuator will reinitialize and should no obey the limits
(def minPosMm -45.0)
(def maxPosMm 45.0)

;calibration output from calib script
; calibration of the right actuator
(def adcMin 0.446)
(def adcMax 3.089)
(def mvPerMm 24.818)
(def degPerMm 193.030)
(def adcZero 1.767)

;calibration of the left actuator
;(def adcMin 0.540)
;(def adcMax 3.174)
;(def mvPerMm 24.729)
;(def degPerMm 192.226)
;(def adcZero 1.857)

;calibration output end


(set-servo-min-pos -10000000)
(set-servo-max-pos 10000000)
(set-servo-power 20 0)    
(def runway 106.5)
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

(def #positionSensor (get-adc 0))
(def calibAdcValStart 0.9)

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
    (progn
        (recv ((event-data-rx . (? data)) (proc-data data))
              (_ nil))
        (event-handler)
))

(defun error-stop (errorStr errorCode)
    (progn
    (print "Stopped due to error!")
    (print errorStr)
    (def errorCodeOut errorCode)
    (loopwhile t (sleep 1.0))
    
))

(event-register-handler (spawn event-handler))
(event-enable 'event-data-rx)



;go to the lower calibration point
(print "Going to actual calib point...")
  
(loopwhile t
        (progn
        (def currentPos (get-servo-pos))
        (def currentPosMm (/ currentPos degPerMm))
        (def currentIn (abs (get-current))) 
        (def #positionSensor (get-adc 0))
        
        (if (> #positionSensor adcZero) (set-servo-pos-speed 100000 1000) (set-servo-pos-speed -100000 1000))
        
        (if (> currentIn 10.0) (def limitCnt (+ limitCnt 1)) (def limitCnt 0))
        
        (if (> limitCnt 50) (error-stop "Hit current limit while going to calib point" 1))    
        
        
        (if (< (abs (- #positionSensor adcZero)) 0.05) (break))
        (sleep 0.001)
        )
        
)

(set-handbrake 0.5)
(sleep 0.1)

(def #positionSensor (get-adc 0))
(def #posSense (- (- runway (/ (* (- #positionSensor adcMin) 1000) mvPerMm)) (/ runway 2.0)))
 
(reset-servo-pos (* #posSense degPerMm))
(set-servo-min-pos (* minPosMm degPerMm))
(set-servo-max-pos (* maxPosMm degPerMm))
(def currentPos (get-servo-pos))

(set-servo-power 100 1)    
(print "Calibrated. Activating Control...")

(def currentPos (get-servo-pos))
(def currentPosMm (/ currentPos degPerMm))
(def #positionSensor (get-adc 0))
(def #posSense (- (- runway (/ (* (- #positionSensor adcMin) 1000) mvPerMm)) (/ runway 2.0)))
(def posDiff0 (abs (- #posSense currentPosMm)))
      

(loopwhile t (progn
    
        (def currentPos (get-servo-pos))
        (def currentPosMm (/ currentPos degPerMm))
        (def currentIn (abs (get-current-in))) 
        (def vbus (get-vin)) 
        (def rpm (get-rpm))
        (def #positionSensor (get-adc 0))
        (def #posSense (- (- runway (/ (* (- #positionSensor adcMin) 1000) mvPerMm)) (/ runway 2.0)))
        (def posDiff (abs (- #posSense currentPosMm posDiff0)))
        
        (bufset-i16 data-out 0 (* currentPosMm 100))
        (bufset-i16 data-out 2 (* currentIn vbus))
        (bufset-i16 data-out 4 rpm)
       
        (if (= ctrlActive 0) (bufset-u8 data-out 6 0) (bufset-u8 data-out 6 1))
        (bufset-u8 data-out 7 errorCodeOut)
        
        (if (and (!= (get-fault) lastFault) (!= (get-fault) 0) (!= (get-fault) 11)) (progn 
            (def faultCnt (+ faultCnt 1))
            (def lastFaultTime (systime))
        ))
        
        (if (> (systime) (+ lastFaultTime 10000)) (def faultCnt 0))
        
        (def lastFault (get-fault))
        (if (> faultCnt 3) (error-stop "Motor controller fault detected" 3))
        
        (if (> posDiff 3.0) (error-stop "Position sensor difference detected" 2))
        (send-data data-out)
        
        (if (= ctrlActive 1) (set-servo-pos-speed (/ (* #setPos degPerMm) 100) (/ (* maxSpeed #setSpeed) 100) ) (set-handbrake 0.5))
       
    
        
        (if (!= lastControlActive ctrlActive) (sleep 0.3) (sleep 0.01))
        (define lastControlActive ctrlActive)
        
))

      ; (loopwhile t (progn (set-handbrake 0.5) (sleep 0.001))) 
                 