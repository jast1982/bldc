

; start where whe are
(reset-servo-pos 0)

(set-servo-min-pos -100000)
(set-servo-max-pos 100000)
(set-servo-power 20 0)    

;how many mm to move for calibration
(def step 100)
(def degPerMm 202.5)
(def runway 147.5)
(def runwayCalib (- (/ runway 2.0) 4.0))
;go all the way up
(def desiredPos 1000000)  
(def inLimitCnt 0)
(loopwhile t
    (progn
        (def adcVal (get-adc 3))
        (if (> (get-current) 10.0) (def inLimitCnt (+ inLimitCnt 1)))
    
        (if (> inLimitCnt 15) (break))
        
        (set-servo-pos-speed desiredPos 800) 
    (sleep 0.01)
)
)


(set-handbrake 0.5)
;sample maximum adc value
(def maxAdc 0)
(def cnt 0)
(loopwhile t
    (progn
       (def maxAdc (+ maxAdc (get-adc 3)))
       (def cnt (+ cnt 1))
       (if (> cnt 50) (break))
       (sleep 0.01)
       
    )
)

(def maxAdc (/ maxAdc cnt))

(def desiredPos (- (get-servo-pos) (* step degPerMm)))  

(loopwhile t
    (progn
               (def adcVal (get-adc 3))

         (set-servo-pos-speed desiredPos 1600) 
         
         (if (< (abs (- desiredPos (get-servo-pos))) 100) (break))
    (sleep 0.01)
)
)

(set-handbrake 0.5)

(def adcStep 0)
(def cnt 0)
(loopwhile t
    (progn
        
       (def adcStep (+ adcStep (get-adc 3)))
       (def cnt (+ cnt 1))
       (if (> cnt 50) (break))
       (sleep 0.01)
       
    )
)

(def adcStep (/ adcStep cnt))

(def mvPerMm (* (/ (- maxAdc adcStep) step) 1000))
(def zeroAdc (- maxAdc (* runwayCalib (/ mvPerMm 1000))))

(print (str-from-n mvPerMm "(def mvPerMm %.3f)"))
(print (str-from-n zeroAdc "(def zeroAdc %.3f)"))
  
