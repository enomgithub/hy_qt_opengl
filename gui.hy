(import math)
(import sys)

(import [PySide2 [QtCore QtGui QtOpenGL QtWidgets]])
(try
  (import [OpenGL [GL]])
  (except [ImportError]
    (setv app ((. QtWidgets QApplication) (. sys argv)))
    (setv message-box
          ((. QtWidgets QMessageBox) (. QtWidgets QMessageBox Critical)
                                     "OpenGL hellogl"
                                     "PyOpenGL must be installed to run this example."
                                     (. QtWidgets QMessageBox Close)))
    ((. message-box setDetailedText) "Run:\npip install PyOpenGL PyOpenGL_accelerate")
    ((. message-box exec-))
    ((. sys exit) 1)))

; math.piは精度が低いため、定数を用意する
(setv *pi* 3.14159265358979323846)


(defclass Window [(. QtWidgets QWidget)]
  (defn --init-- [self &optional [parent None]]
    ((. (super) --init--) parent)

    (setv (. self gl-widget) (GLWidget)
          (. self x-slider) ((. self create-slider))
          (. self y-slider) ((. self create-slider))
          (. self z-slider) ((. self create-slider))

          main-layout ((. QtWidgets QHBoxLayout)))

    (list (map (fn [-widget]
                 ((. main-layout addWidget) -widget))
               [(. self gl-widget)
                (. self x-slider)
                (. self y-slider)
                (. self z-slider)]))
    ((. self setLayout) main-layout)

    ((. self x-slider setValue) (* 170 16))
    ((. self y-slider setValue) (* 160 16))
    ((. self z-slider setValue) (* 90 16))

    ((. self setWindowTitle) ((. self tr) "Hello GL"))
    
    ((. self x-slider valueChanged connect) (. self gl-widget setXRotation))
    ((. self gl-widget xRotationChanged connect) (. self x-slider setValue))

    ((. self y-slider valueChanged connect) (. self gl-widget setYRotation))
    ((. self gl-widget yRotationChanged connect) (. self y-slider setValue))

    ((. self z-slider valueChanged connect) (. self gl-widget setZRotation))
    ((. self gl-widget zRotationChanged connect) (. self z-slider setValue))

    None)
  
  (defn create-slider [self]
    (setv slider ((. QtWidgets QSlider) (. QtCore Qt Vertical)))
    
    ((. slider setRange) 0 (* 360 16))
    ((. slider setSingleStep) 16)
    ((. slider setPageStep) (* 15 16))
    ((. slider setTickInterval) (* 15 16))
    ((. slider setTickPosition) (. QtWidgets QSlider TicksRight))

    slider))


(defclass GLWidget [(. QtOpenGL QGLWidget)]
  (setv xRotationChanged ((. QtCore Signal) int)
        yRotationChanged ((. QtCore Signal) int)
        zRotationChanged ((. QtCore Signal) int))

  (defn --init-- [self &optional [parent None]]
    ((. (super) --init--) parent)
    
    (setv (. self object) 0
          (. self x-rot) 0
          (. self y-rot) 0
          (. self z-rot) 0

          (. self last-pos) ((. QtCore QPoint))

          (. self trolltech-green) ((. QtGui QColor fromCmykF) 0.40 0.0 1.0 0.0)
          (. self trolltech-purple) ((. QtGui QColor fromCmykF) 0.39 0.39 0.0 0.0))

    None)
 
  (defn minimumSizeHint [self]
    ((. QtCore QSize) 50 50))
  
  (defn sizeHint [self]
    ((. QtCore QSize) 400 400))

  #@(((. QtCore Slot) int)
    (defn setXRotation [self angle]
      (setv angle ((. self normalizeAngle) angle))
      (when (!= angle (. self x-rot))
            (do
              (setv (. self x-rot) angle)
              ((. self xRotationChanged emit) angle)
              ((. self updateGL))))
      None))

  #@(((. QtCore Slot) int)
    (defn setYRotation [self angle]
      (setv angle ((. self normalizeAngle) angle))
      (when (!= angle (. self y-rot))
            (do
              (setv (. self y-rot) angle)
              ((. self yRotationChanged emit) angle)
              ((. self updateGL))))
      None))

  #@(((. QtCore Slot) int)
    (defn setZRotation [self angle]
      (setv angle ((. self normalizeAngle) angle))
      (when (!= angle (. self z-rot))
            (do
              (setv (. self z-rot) angle)
              ((. self zRotationChanged emit) angle)
              ((. self updateGL))))
      None))
  
  (defn initializeGL [self]
    ((. self qglClearColor) ((. self trolltech-purple darker)))
    (setv (. self object) ((. self makeObject)))
    ((. GL glShadeModel) (. GL GL_FLAT))
    ((. GL glEnable) (. GL GL_DEPTH_TEST))
    ((. GL glEnable) (. GL GL_CULL_FACE))
    None)
  
  (defn paintGL [self]
    ((. GL glClear) (| (. GL GL_COLOR_BUFFER_BIT) (. GL GL_DEPTH_BUFFER_BIT)))
    ((. GL glLoadIdentity))
    ((. GL glTranslated) 0.0 0.0 -10.0)
    (list (map (fn [-rot] ((. GL glRotated) #* -rot))
               [(, (/ (. self x-rot) 16.0) 1.0 0.0 0.0)
                (, (/ (. self y-rot) 16.0) 0.0 1.0 0.0)
                (, (/ (. self z-rot) 16.0) 0.0 0.0 1.0)]))
    ((. GL glCallList) (. self object))
    None)
  
  (defn resizeGL [self width height]
    (setv side (min width height))
    ((. GL glViewport) (int (/ (- width side) 2))
                       (int (/ (- height side) 2))
                       side
                       side)
    ((. GL glMatrixMode) (. GL GL_PROJECTION))
    ((. GL glLoadIdentity))
    ((. GL glOrtho) -0.5 0.5 -0.5 0.5 4.0 15.0)
    ((. GL glMatrixMode) (. GL GL_MODELVIEW))
    None)
  
  (defn mousePressEvent [self event]
    (setv (. self last-pos) ((. QtCore QPoint) ((. event pos))))
    None)
  
  (defn mouseMoveEvent [self event]
    (setv dx (- ((. event x)) ((. self last-pos x)))
          dy (- ((. event y)) ((. self last-pos y))))

    (cond [(& ((. event buttons)) (. QtCore Qt LeftButton))
           ((. self setXRotation) (+ (. self x-rot) (* 8 dy)))
           ((. self setYRotation) (+ (. self y-rot) (* 8 dx)))]
          [(& ((. event buttons)) (. QtCore Qt RightButton))
           ((. self setXRotation) (+ (. self x-rot) (* 8 dy)))
           ((. self setZRotation) (+ (. self z-rot) (* 8 dx)))])
    (setv (. self last-pos) ((. QtCore QPoint) ((. event pos))))
    None)
  
  (defn -create-sector [self i num-sectors]
    (setv angle1 (/ (* i 2 *pi*) num-sectors)
          x5 (* 0.30 ((. math sin) angle1))
          y5 (* 0.30 ((. math cos) angle1))
          x6 (* 0.20 ((. math sin) angle1))
          y6 (* 0.20 ((. math cos) angle1))

          angle2 (/ (* (+ i 1) 2 *pi*) num-sectors)
          x7 (* 0.20 ((. math sin) angle2))
          y7 (* 0.20 ((. math cos) angle2))
          x8 (* 0.30 ((. math sin) angle2))
          y8 (* 0.30 ((. math cos) angle2)))

    ((. self quad) x5 y5 x6 y6 x7 y7 x8 y8)

    ((. self extrude) x6 y6 x7 y7)
    ((. self extrude) x8 y8 x5 y5)

    None)

  (defn makeObject [self]
    (setv gen-list ((. GL glGenLists) 1))
    ((. GL glNewList) gen-list (. GL GL_COMPILE))

    ((. GL glBegin) (. GL GL_QUADS))

    (setv x1 0.06
          y1 -0.14
          x2 0.14
          y2 -0.06
          x3 0.08
          y3 0.00
          x4 0.30
          y4 0.22)

    (list (map (fn [-list] ((. self quad) #* -list))
               [[x1 y1 x2 y2 y2 x2 y1 x1]
                [x3 y3 x4 y4 y4 x4 y3 x3]]))

    (list (map (fn [-list] ((. self extrude) #* -list))
               [[x1 y1 x2 y2]
                [x2 y2 y2 x2]
                [y2 x2 y1 x1]
                [y1 x1 x1 y1]
                [x3 y3 x4 y4]
                [x4 y4 y4 x4]
                [y4 x4 y3 x3]]))

    (setv num-sectors 200)

    (list (map (fn [i] ((. self -create-sector) i num-sectors))
               (range num-sectors)))

    ((. GL glEnd))
    ((. GL glEndList))
    gen-list)
  
  (defn quad [self x1 y1 x2 y2 x3 y3 x4 y4]
    ((. self qglColor) (. self trolltech-green))

    (list (map (fn [-list] ((. GL glVertex3d) #* -list)) 
               [[x1 y1 0.05]
                [x2 y2 0.05]
                [x3 y3 0.05]
                [x4 y4 0.05]
                [x4 y4 -0.05]
                [x3 y3 -0.05]
                [x2 y2 -0.05]
                [x1 y1 -0.05]]))
    None)

  (defn extrude [self x1 y1 x2 y2]
    ((. self qglColor) ((. self trolltech-green darker) (+ 250 (int (* 100 x1)))))

    (list (map (fn [-list] ((. GL glVertex3d) #* -list))
               [[x1 y1 -0.05]
                [x2 y2 -0.05]
                [x2 y2 0.05]
                [x1 y1 0.05]]))
    None)

  (defn normalizeAngle [self angle]
    (while (< angle 0)
           (setv angle (+ angle (* 360 16))))
    (while (> angle (* 360 16))
           (setv angle (- angle (* 360 16))))
    angle))
  

(when (= --name-- "__main__")
      (setv app ((. QtWidgets QApplication) (. sys argv)))
      (setv window (Window))
      ((. window show))
      (setv res ((. app exec-)))
      ((. sys exit) res))