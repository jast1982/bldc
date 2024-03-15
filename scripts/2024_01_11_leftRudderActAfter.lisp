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
(def triggerParamSend 0)
(def triggerParamSendCnt 0)

(defun proc-eid (id data)
        (if (= uiTimeout 0)
        (progn
      ;  (print (buflen data))
        (if (= actType 1) (define #setPos (bufget-i16 data 2)) (define #setPos (bufget-i16 data 0)))
        (define #setSpeed (bufget-u8 data 6))
        (define #setFlags (bufget-u8 data 7))
        (define #setAcc (bufget-u8 data 4))
        (define #setMaxAngle (bufget-u8 data 5))
        
        
        (if (= #setFlags 1) (define ctrlActive 1)
                (progn
                   ; (if (= ctrlActive 1) (def triggerCalib 1))
                    (define ctrlActive 0)
                    
                     (if (and (= #setFlags 200) (= actType 0))
                        (progn
                            (define #setPos 0)
    
                            ;store new mvPerMm for flap actuator
                            (eeprom-store-f 3 (bufget-f32 data 0 'little-endian))
                            
                            (print (str-from-n (bufget-f32 data 0 'little-endian) "new mvPerMm: %3.2f"))
                            (def triggerParamSend 0)
                            (def triggerParamSendCnt 10)

                        )
                     )
                     
                     (if (and (= #setFlags 201) (= actType 0))
                        (progn
                            (define #setPos 0)
    
                            ;store new adcZero for flap actuator
                            (eeprom-store-f 4 (bufget-f32 data 0 'little-endian))
                            (def adcZero (eeprom-read-f 4))
                            (print (str-from-n adcZero "new adcZero: %3.2f"))
                             (def triggerParamSend 1)
                            (def triggerParamSendCnt 10)
                           
                        )
                     )
                     
                     (if (and (= #setFlags 202) (= actType 0))
                        (progn
                            (define #setPos 0)
    
                            ;store new minPos for flap actuator
                            (eeprom-store-f 5 (bufget-f32 data 0 'little-endian))
                            
                            (def minPosMm (eeprom-read-f 5))
                            (print (str-from-n minPosMm "new minPosMm: %3.2f"))             
                            (set-servo-min-pos (* minPosMm degPerMm))
 
                            (def triggerParamSend 3)
                            (def triggerParamSendCnt 10)
                        )
                     )

                     (if (and (= #setFlags 203) (= actType 0))
                        (progn
                            (define #setPos 0)
    
                            ;store new maxPos for flap actuator
                            (eeprom-store-f 6 (bufget-f32 data 0 'little-endian))
                            (def maxPosMm (eeprom-read-f 6))
                            (print (str-from-n maxPosMm "new maxPosMm: %3.2f"))
                            (set-servo-max-pos (* maxPosMm degPerMm))                                
                             (def triggerParamSend 3)
                            (def triggerParamSendCnt 10)
                       )
                     )
                     (if (and (= #setFlags 204) (= actType 0))
                        (progn
                            (define #setPos 0)
    
                            ;store new txid for flap actuator
                            (eeprom-store-i 2 (bufget-i32 data 0 'little-endian))
                            
                            (print (str-from-n (bufget-i32 data 0 'little-endian) "New TxId: 0x%x"))

                            (def triggerParamSend 4)
                            (def triggerParamSendCnt 10)
                            
                        )
                     )
                 
                     (if (and (= #setFlags 205) (= actType 0))
                        (progn
                            (define #setPos 0)
    
                            ;store new id for flap actuator
                            (eeprom-store-i 1 (bufget-i32 data 0 'little-endian))
                            (print (str-from-n (bufget-i32 data 0 'little-endian) "New ActType: %i"))
                        
                            (def triggerParamSend 5)
                            (def triggerParamSendCnt 10)
                        )
                     )
                     
                       (if (and (= #setFlags 206) (= actType 0))
                        (progn
                            (define #setPos 0)
    
                            ;store new id for flap actuator
                            (eeprom-store-i 0 (bufget-i32 data 0 'little-endian))
                            (print (str-from-n (bufget-i32 data 0 'little-endian) "New ActId: %i"))
                        
                            (def triggerParamSend 6)
                            (def triggerParamSendCnt 10)
                        )
                     )
                     
                     
                     (if (and (= #setFlags 210) (= actType 1))
                        (progn
                            (define #setPos 0)
    
                            ;store new mvPerMm for rudder actuator
                            (eeprom-store-f 3 (bufget-f32 data 0 'little-endian))
                            
                            (print (str-from-n (bufget-f32 data 0 'little-endian) "new mvPerMm: %3.2f"))
                            
                            (def triggerParamSend 0)
                            (def triggerParamSendCnt 10)
                        )
                     )
                     
                     (if (and (= #setFlags 211) (= actType 1))
                        (progn
                            (define #setPos 0)
    
                            ;store new adcZero for rudder actuator
                            (eeprom-store-f 4 (bufget-f32 data 0 'little-endian))
                            (def adcZero (eeprom-read-f 4))
                            (print (str-from-n adcZero "new adcZero: %3.2f"))
                            
                            (def triggerParamSend 1)
                            (def triggerParamSendCnt 10)
                        )
                     )
                     
                     (if (and (= #setFlags 212) (= actType 1))
                        (progn
                            (define #setPos 0)
    
                            ;store new minPos for rudder actuator
                            (eeprom-store-f 5 (bufget-f32 data 0 'little-endian))
                            
                            (def minPosMm (eeprom-read-f 5))
                            (print (str-from-n minPosMm "new minPosMm: %3.2f"))             
                            (set-servo-min-pos (* minPosMm degPerMm))
 
                            (def triggerParamSend 2)
                            (def triggerParamSendCnt 10)
                        )
                     )

                     (if (and (= #setFlags 213) (= actType 1))
                        (progn
                            (define #setPos 0)
    
                            ;store new maxPos for rudder actuator
                            (eeprom-store-f 6 (bufget-f32 data 0 'little-endian))
                            (def maxPosMm (eeprom-read-f 6))
                            (print (str-from-n maxPosMm "new maxPosMm: %3.2f"))
                            (set-servo-max-pos (* maxPosMm degPerMm))                                
                            (def triggerParamSend 3)
                            (def triggerParamSendCnt 10)
                       )
                     )
                     (if (and (= #setFlags 214) (= actType 1))
                        (progn
                            (define #setPos 0)
    
                            ;store new txid for rudder actuator
                            (eeprom-store-i 2 (bufget-i32 data 0 'little-endian))
                            
                            (print (str-from-n (bufget-i32 data 0 'little-endian) "New TxId: 0x%x"))

                            
                            (def triggerParamSend 4)
                            (def triggerParamSendCnt 10)
                        )
                     )
                 
                     (if (and (= #setFlags 215) (= actType 1))
                        (progn
                            (define #setPos 0)
    
                            ;store new id for rudder actuator
                            (eeprom-store-i 1 (bufget-i32 data 0 'little-endian))
                            (print (str-from-n (bufget-i32 data 0 'little-endian) "New ActType: %i"))
                        
                            (def triggerParamSend 5)
                            (def triggerParamSendCnt 10)
                       )
                     )
                     
                      (if (and (= #setFlags 216) (= actType 1))
                        (progn
                            (define #setPos 0)
    
                            ;store new id for flap actuator
                            (eeprom-store-i 0 (bufget-i32 data 0 'little-endian))
                            (print (str-from-n (bufget-i32 data 0 'little-endian) "New ActId: %i"))
                        
                            (def triggerParamSend 6)
                            (def triggerParamSendCnt 10)
                        )
                     )
                     
                     (if  (= #setFlags 220) 
                        (progn
                            (define #setPos 0)
    
                            ;just poll a parameter
                            (def triggerParamSend (bufget-i32 data 0 'little-endian))
                            (def triggerParamSendCnt 10)
                       )
                     )
                     
                )
         )
                 
        
       ; (print "pos:" #setPos #setSpeed #setFlags)
)))


; This is received from the QML-program which acts as a remote control for the robot
(defun proc-data (data)
    (progn    
    (define #setFlags (bufget-u8 data 7))
    
    (if (!= #setFlags 0) (progn
        (define #setPos (bufget-i16 data 0))
        (define #setSpeed (bufget-u8 data 6))
        (def uiTimeout 100)
          (define ctrlActive 1))
         ;else
         (define ctrlActive 0))
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
        (if (and (!= lastFault 0) (!= lastFault 11)) (error-stop "Motor controller fault detected" 3))
        (if (< (abs (- #positionSensor adcCalibPoint)) 0.05) (break))
        (sleep 0.001)
        )
        
)

(set-handbrake 0.5)
(sleep 0.1)
(def calibValueCnt 0)
(def calibCnt 0)
(def calibValue 0.0)
(loopwhile t
        (progn

        (def calibCnt (+ calibcnt 1))
        
        (if (> calibCnt 100) (progn
            (def #positionSensor (get-adc 3))

            (def #posSense (/ (* (- #positionSensor adcZero) 1000) mvPerMm))
            
            (def calibValue (+ calibValue #posSense))
            (def calibValueCnt (+ calibValueCnt 1))
        
        ))
        
        (if (> calibCnt 400) (break))
        (sleep 0.01)
        )
 )
 
(def calibValue (/ calibValue calibValueCnt))

(def #positionSensor (get-adc 3))
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

(loopwhile t (progn
    
        (def currentPos (get-servo-pos))
        (def currentPosMm (/ currentPos degPerMm))
        (def currentIn (abs (get-current))) 
        (def vbus (get-vin)) 
        (def rpm (get-rpm))
        (def #positionSensor (get-adc 3))
        
        (def deltaT (secs-since lastTime))
        (def lastTime (systime))
        
        (def #posSense (/ (* (- #positionSensor adcZero) 1000) mvPerMm))
        (def posDiff (- (abs (- #posSense currentPosMm) ) posDiff0))
        
        
        (if (> triggerParamSendCnt 0) (progn           
            (bufset-i16 data-out 0 0x3fff)
            (bufset-i8 data-out 2 triggerParamSend)
            (if (= triggerParamSend 0) (bufset-f32 data-out 4 mvPerMm 'little-endian))
            (if (= triggerParamSend 1) (bufset-f32 data-out 4 adcZero 'little-endian))
            (if (= triggerParamSend 2) (bufset-f32 data-out 4 minPosMm 'little-endian))
            (if (= triggerParamSend 3) (bufset-f32 data-out 4 maxPosMm 'little-endian))
            (if (= triggerParamSend 4) (bufset-i32 data-out 4 txId 'little-endian))
            (if (= triggerParamSend 5) (bufset-i32 data-out 4 actType 'little-endian))
            (if (= triggerParamSend 6) (bufset-i32 data-out 4 id 'little-endian))
            
            (def triggerParamSendCnt 0)
            
            
        ) 
        (progn
        
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
        
        )
        )
        (if (> uiTimeout 0) (def uiTimeout (- uiTimeout 1)))
        
        (if (and (!= lastFault 0) (!= lastFault 11) (!= lastFault 4)) (error-stop "Motor controller fault detected" 3)) 
        ;(if (< (abs currentPosMm) 15) (if (> posDiff 6.0) (error-stop "Position sensor difference detected" 2)))
        (send-data data-out)
        (can-send-eid txId (list (bufget-u8 data-out 0) (bufget-u8 data-out 1) (bufget-u8 data-out 2) (bufget-u8 data-out 3) (bufget-u8 data-out 4) (bufget-u8 data-out 5) (bufget-u8 data-out 6) (bufget-u8 data-out 7) ))
        
        (if (= errorCodeOut 0) (if (= ctrlActive 1) (set-servo-pos-speed (/ (* #setPos degPerMm) 100) (/ (* maxSpeed #setSpeed) 100) ) (set-handbrake 0.5))
        )
    
        
        (sleep 0.001)
        
))

      ; (loopwhile t (progn (set-handbrake 0.5) (sleep 0.001))) 
                 