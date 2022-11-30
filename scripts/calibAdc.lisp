
;position sensor parameters
(def maxPosFiltered 0.0)
(def minPosFiltered 0.0)
(def maxAdcValFiltered 0.0)
(def calibAdcCnt 0)
(def minAdcValFiltered 0.0)

;calibration parameters
(def maxAngleDiffCalib 15.0)
(def desiredChangeCalib 2.0)
(def runway 106.5)
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

(loopwhile t
    (progn
        
; read adc of position sensor
   (def positionSensor (get-adc 0))

; test program
    (if (= initState 0) ( progn
        (def desiredPos (- desiredPos desiredChangeCalib))        
        (def maxAngleDiff maxAngleDiffCalib)
        
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
        (def desiredPos (+ desiredPos desiredChangeCalib))        
        (def maxAngleDiff maxAngleDiffCalib)
   
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
            (print (str-from-n minAdcValFiltered "MinAdc: %.3f"))
            (print (str-from-n maxAdcValFiltered "MaxAdc: %.3f"))
            (print (str-from-n minPosFiltered "MinPos: %.3f"))
            (print (str-from-n maxPosFiltered "MaxPos: %.3f"))
            (print (str-from-n mvPerMm "Scale (mv/mm): %.3f"))
            (print (str-from-n degPerMm "Scale (deg/mm): %.3f"))
        ))
        
        
    ))

;read encoder, flip position to match vesc internal position
        (def currentAngle (* (get-encoder) -1))        
        (if (< currentAngle 0) (def currentAngle (+ currentAngle 360.0)))

;update current global position
        (def angleDiff (- currentAngle lastAngle))
        
        (if (> angleDiff 180.0) (def currentPosIdx (- currentPosIdx 1)))
        (if (< angleDiff -180.0) (def currentPosIdx (+ currentPosIdx 1)))
        
        (def currentPos (* currentPosIdx 360))
        (def currentPos (+ currentPos currentAngle))
        
 
        (def posDiff (- desiredPos currentPos))
        
        (if (and (> posDiff (* maxAngleDiff -1)) (< posDiff maxAngleDiff)) (def inLimitCnt 0))
        
        (if (> posDiff maxAngleDiff) (progn
             (def inLimitCnt (+ inLimitCnt 1))
             (def desiredPos (+ currentPos maxAngleDiff))))
           
        (if (< posDiff (* maxAngleDiff -1)) (progn
             (def inLimitCnt (+ inLimitCnt 1))
             (def desiredPos (- currentPos maxAngleDiff))))

       
        (def desiredAngle (mod desiredPos 360.0))
        
        (def lastPos currentPos)
        (def lastAngle currentAngle)
        
        (if (< initState 128) (set-pos desiredAngle) (set-handbrake 0.5))

        (sleep 0.001)
        ))