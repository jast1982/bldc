;; this need to be -1 if config->foc->encoder->inverted=true, else 1

;position sensor parameters
(def maxPosFiltered 0.0)
(def minPosFiltered 0.0)
(def maxAdcValFiltered 0.0)
(def calibAdcCnt 0)
(def minAdcValFiltered 0.0)

;calibration parameters
(def maxAngleDiffCalib 100.0)
(def runway 147.5)
(def inhibitLimitCnt 0)
;run parameters
(def inLimitCnt 0)

;default values
(def desiredPos 0.0)
(def lastAngle 0)
(def currentPosIdx 0)
(def currentPos 0)
(def lastPos 0)
(def initState 0)
;min: 0.463
;max: 3.37

(reset-servo-pos 0)

(set-servo-min-pos -100000)
(set-servo-max-pos 100000)
(set-servo-power 40 0)    

(loopwhile t
    (progn
        
; read adc of position sensor
   (def positionSensor (get-adc 3))

; test program
    (if (= initState 0) ( progn
        (def desiredPos 1000000)        
        
        (if (< inhibitLimitCnt 200) (progn (def inLimintCnt 0) (def inhibitLimitCnt (+ inhibitLimitCnt 1))))
        
        (if (< inLimitCnt 100) ( progn
            (def maxAdcValFiltered 0.0)
            (def calibAdcCnt 0)
            (def minAdcValFiltered 0.0)
            (def maxPosFiltered 0.0)

        ))
        
        (if (> inLimitCnt 200) ( progn
            (def maxPosFiltered (+ maxPosFiltered currentPos))
            (def maxAdcValFiltered (+ maxAdcValFiltered positionSensor))
            (def calibAdcCnt (+ calibAdcCnt 1))
        ))

        (if (> inLimitCnt 300) ( progn
            (def maxAdcValFiltered (/ maxAdcValFiltered calibAdcCnt))              
            (def maxPosFiltered (/ maxPosFiltered calibAdcCnt))              
            (def initState 1)
            (def inLimitCnt 0)        
            (def inhibitLimitCnt 0)    
        ))

    ))
; goto zero position    
    (if (= initState 1) (progn
        (def desiredPos -1000000)        
      
         (if (< inhibitLimitCnt 200) (progn (def inLimintCnt 0) (def inhibitLimitCnt (+ inhibitLimitCnt 1))))
  
          
        (if (< inLimitCnt 100) ( progn
            (def calibAdcCnt 0)
            (def minAdcValFiltered 0.0)
            (def minPosFiltered 0.0)
        ))

        (if (> inLimitCnt 200) ( progn
        
            (def minPosFiltered (+ minPosFiltered currentPos))
            (def minAdcValFiltered (+ minAdcValFiltered positionSensor))
            (def calibAdcCnt (+ calibAdcCnt 1))
        ))

        (if (> inLimitCnt 300) ( progn
            (def initState 255)
            (def inLimitCnt 0) 
            (def minAdcValFiltered (/ minAdcValFiltered calibAdcCnt))            
            (def minPosFiltered (/ minPosFiltered calibAdcCnt))              
            (def mvPerMm (/ (* (- maxAdcValFiltered minAdcValFiltered) 1000.0) runway) )            
            (def degPerMm (/ (- maxPosFiltered minPosFiltered) runway) )            
            (def degPerMm (abs degPerMm))
            
            (print (str-from-n minAdcValFiltered "(def adcMin %.3f)"))
            (print (str-from-n maxAdcValFiltered "(def adcMax %.3f)"))
            (print (str-from-n mvPerMm "(def mvPerMm %.3f)"))
            (print (str-from-n degPerMm "(def degPerMm %.3f)"))
            (print (str-from-n (+ minAdcValFiltered (/ (- maxAdcValFiltered minAdcValFiltered) 2) )"(def adcZero %.3f)"))
        ))
        
        
    ))

;read encoder, flip position to match vesc internal position
       
       
        
 
        (def currentPos (get-servo-pos))
        (if (> (get-current) 15.0) (def inLimitCnt (+ inLimitCnt 1)))
    
        
        (if (< initState 128)  (set-servo-pos-speed desiredPos 800) (set-handbrake 0.5))

        (sleep 0.001)
        ))