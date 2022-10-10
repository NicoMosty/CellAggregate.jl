# Marco teórico

## Explicación del modelo "Off Lattice a partir del Centro de Masa"

Los modelos *Off-Lattice* (CBM) se basan en el seguimiento del centro de masa de cada partícula a partir de las interacciones mecánicas presentes entre las células. Aunque existen otros modelos basados en el centro de masa como lo son los modelos **Vertex** que requiere el cálculo de la tensión interfacial y presión de las células [@mathias2020]. Para el caso del modelo basado en el centro de masa, se logra una relación equilibrada con respecto a la eficiencia numérica y la capacidad de incorporación de modelos contínuos de la mecánica celular presente en la agragación de las células teniendo en cuenta aspectos importantes como lo son la temporalidad del sistema a partir de la biofísica del sistema [@mathias2020].

Para el caso del modelo *Off-Lattice* (CBM) se han propuesto diferentes modelos físicos a partir de la interacción entre las células para proporcionar descripciones del sistema con modelos parecidos a Lattice Boltzmann como lo son el modelo *Johnson-Keller-Roberts*.

De manera general, para los diferentes modelos *Off-lattice* se usa la tercera ley de Newton, donde:

\begin{equation} 
    m_i*a=m_i*\ddot{x}_i=F_i \label{eq:third_newton}
\end{equation} 

A partir de la suma de las fuerzas en cada célula se halla la siguiente ecuación:

\begin{equation}
    m_i*\ddot{x}_i=-\nabla*\dot{x}_i+\sum_{j \neq i}{F_{ij}} \label{eq:sum_third_newton}
\end{equation} 

Para la simulación se usa la siguiente ecuación simplificada, donde:

\begin{equation}
    \lambda*\sum_{j}{\dot{x}_i-\dot{x}_j}=\sum_{j}{F^{S}_{ij}+F^{a}_{ij}} \label{eq:sum_forces} 
\end{equation} 

Donde para el caso presentado se tienen las  fuerzas repulsivas ($F^{S}_{ij}$) & fuerzas atractivas ($F^{a}_{ij}$).

El sistema representado a partir del centro de masa puede ser representado de la siguiente manera:

![Ilustración del modelo de centro de masa. Se asume fuerzas de atracción y repulsión [@mathias2020]](img/1.png){width=220}

Para calcular la evolución temporal, normalmente se usa el método de Euler hacia delante ("*foward Euler method*"):

\begin{equation} 
    y_{n+1}=y_n+\Delta t*f(t_n,y_n) \label{eq:foward_euler_method}
\end{equation} 

Aunque actualmente se han usado métodos con varios pasos teniendo en cuenta valores pasados. Entre los métodos más usados se encuentra el método de Adams-Bashforth, donde:

\begin{equation} 
    y_{n+1}=y_n+\frac{3}{2}*\Delta t*f(t_n,y_n)-\frac{1}{2}*\Delta t*f(t_{n-1}, y_{n-1}) \label{eq:adam_bashforth_equation}
\end{equation} 

Para la simulación es este tipo de sistemas se tiene software generado como lo puede ser *Ya||a* [@germann2019] que usa el lenguage de progrmamación CUDA usando GPU (tarjetas gráficas) permitiendo su paralelizacióñ en cada paso de Euler en un proceso similar hallado en la paralelización en los modelos de Cellular Potts [@tapia2011].

## Modelos de fuerzas características de la interacción celular
En los últimos años se han desarrollado y usado diferentes interacciones con los cuales se han modelado la interacción entre las celulas presentes en el agregado celular, entre los modelos mas usados se tiene los siguientes:

### Modelo Cúbico
Este modelo fue desarrollado por [@delile2017]. En este modelo se asume la relación entre las células como fuerzas cúbicas par ale caso de las fuerzas atractivas y las fuerzas de resorte lineal como la interacción de repulsión. Este modelo ha sido usado en un framework llamado *MecaGen*. Las interacciones son las siguientes:

\begin{equation} 
    F^{Cubic}( r) =\left
    \{\begin{matrix}
        \mu \cdotp ( r-r_{max})^{2} \cdotp *( r-r_{min})\\
        si\ r \leqslant r_{max}\\
        \\\\
        0\\
        si\ r_{max} < r
    \end{matrix}\right. 
    \label{eq:mecagen_eq}
\end{equation} 

### Modelo Lineal Generalizado de resorte
Este modelo fue desarrollado por [@cooper2020]. Este modelo usaba la suma de polinómios para la representación de la atracción y repulsión. El modelo ha sido usado en el software llamado "*Chaste*" usado para el estudio del cáncer. Las interacciones se representan con la siguinete ecuación, donde:

\begin{equation}
    F^{GLS}( r) =\left
        \{\begin{matrix}
        \mu \cdotp log( 1+( r-r_{min}))\\
        si\ r\leqslant r_{min}\\
        \\\\
        \mu \cdotp ( r-r_{min}) \cdotp exp( -\alpha ( r-r_{min}))\\
        si\ r_{min} < r\leqslant r_{max}\\
        \\\\
        0\\
        si\ r  >r_{max}
    \end{matrix}\right.
    \label{eq:GLS_eq}
\end{equation}

Para los dos modelos mencionados anteriormente se tiene que **$\mu$** es el parámetro que representa la relación de atracción & repulsión de las células, **$r_{min}$** es la distancia mínima entre las células donde se inicia la repulsión de las células en los agregados, **$r_{max}$** es la distancia máxima donde no hay interacción de atracción del medio presente entre las células & **$s$** es un factor que determina el ancho de la 
fuerza que es dependiente de **$r_{max}$**.

# Metodología
![A](img/2.png){width=220}

# Bibliografia
\footnotesize
