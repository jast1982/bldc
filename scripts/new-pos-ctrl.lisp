(set-servo-min-pos -10000000)
(set-servo-max-pos 10000000)
(set-servo-power 10 0)    
(def minAdcOffset 0.462)
(def degPerMm 204.488)
(def mvPerMm 27.356)
(def runway 106.5)
(def ctrlActive 0)
(def limitCnt 0)
(define #setPos 0)
(define #setSpeed 10)
(define #setFlags 0)  
(define data-out (array-create 8))
(define maxSpeed 25000)
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
        (print "pos:" #setPos #setSpeed #setFlags)
        
        )
  )

(defun event-handler ()
    (progn
        (recv ((event-data-rx . (? data)) (proc-data data))
              (_ nil))
        (event-handler)
))

(event-register-handler (spawn event-handler))
(event-enable 'event-data-rx)

; if neccessary move the cylinder up to find the calibration point
(if (< #positionSensor calibAdcValStart) 

(loopwhile t
        (progn
        (def #positionSensor (get-adc 0))
        (def currentPos (get-servo-pos))
       
        (set-servo-pos-speed 10000 1000)
        
        (if (> #positionSensor calibAdcValStart) (break))
        
        (if (> limitCnt 50) (break))    
        
        ;(if (> currentPos 9500) (progn
        
         ;       (print "Error reaching init point")
                
           ;     (loopwhile t (progn (set-handbrake 0.5) (sleep 0.001))) 
          ;      )
        ;(sleep 0.001)
        ;)
        
)

))

;go to the lower calibration point
        
(loopwhile t
        (progn
        (def currentPos (get-servo-pos))
        (def currentPosMm (/ currentPos degPerMm))
        (def currentIn (abs (get-current))) 
        (def #positionSensor (get-adc 0))
        (def #posSense (* (- (- runway (/ (* (- #positionSensor minAdcOffset) 1000) mvPerMm)) (/ runway 2.0)) -1))
        (def calibAdcVal 0.7)
        (set-servo-pos-speed -100000 3000)
        
        (if (> currentIn 10.0) (def limitCnt (+ limitCnt 1)) (def limitCnt 0))
        
        (if (> limitCnt 50) (break))    
        
        (if (< #positionSensor calibAdcVal) (break))
        (sleep 0.001)
        )
        
)


(def #positionSensor (get-adc 0))
(def #posSense (* (- (- runway (/ (* (- #positionSensor minAdcOffset) 1000) mvPerMm)) (/ runway 2.0)) -1))

(reset-servo-pos (* #posSense degPerMm))
(set-servo-min-pos -9200)
(set-servo-max-pos 9200)


; go home
(loopwhile t
        (progn
        (def currentPos (get-servo-pos))
        (def currentPosMm (/ currentPos degPerMm))
        (def currentIn (abs (get-current))) 
        (def #positionSensor (get-adc 0))
        (def #posSense (* (- (- runway (/ (* (- #positionSensor minAdcOffset) 1000) mvPerMm)) (/ runway 2.0)) -1))
        (def calibAdcVal 0.7)
        (set-servo-pos-speed 0 3000)
        
        (if (> currentPosMm -0.1) (break))
       
         (sleep 0.001)
        )
        
)


(loopwhile t (progn
    
        (def currentPos (get-servo-pos))
        (def currentPosMm (/ currentPos degPerMm))
        (def currentIn (abs (get-current))) 
        (def vbus (get-vin)) 
        (def rpm (get-rpm))
        
        (bufset-i16 data-out 0 currentPosMm)
        (bufset-i16 data-out 2 (* currentIn vbus))
        (bufset-i16 data-out 4 rpm)
       
        (if (= ctrlActive 0) (bufset-u8 data-out 6 0) (bufset-u8 data-out 6 1))
   
        (send-data data-out)
   
        
        (if (= ctrlActive 1) (set-servo-pos-speed (/ (* #setPos degPerMm) 100) (/ (* maxSpeed #setSpeed) 100) ) (set-handbrake 0.5))
       
    
        
        (sleep 0.01)
))

      ; (loopwhile t (progn (set-handbrake 0.5) (sleep 0.001))) 
                 