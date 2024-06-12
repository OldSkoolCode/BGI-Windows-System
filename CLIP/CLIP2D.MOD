IMPLEMENTATION MODULE clip2d;

VAR
  code : CARDINAL;

PROCEDURE clip2d(VAR px,py,qx,qy : INTEGER): BOOLEAN;

PROCEDURE ClipPBottom;
BEGIN
  px := (qx - px)*(YBottom - py) DIV (qy - py) + px;
  py := YBottom;
END ClipPBottom;

PROCEDURE ClipPTop;
BEGIN
  px := (qx - px)*(YTop - py) DIV (qy - py) + px;
  py := YTop;
END ClipPTop;

PROCEDURE ClipPRight;
BEGIN
  py := (qy - py)*(XRight - px) DIV (qx - px) + py;
  px := XRight;
END ClipPRight;

PROCEDURE ClipPLeft;
BEGIN
  py := (qy - py)*(XLeft - px) DIV (qx - px) + py;
  px := XLeft;
END ClipPLeft;

PROCEDURE ClipQBottom;
BEGIN
  qx := (px - qx)*(YBottom - qy) DIV (py - qy) + qx;
  qy := YBottom;
END ClipQBottom;

PROCEDURE ClipQTop;
BEGIN
  qx := (px - qx)*(YTop - qy) DIV (py - qy) + qx;
  qy := YTop;
END ClipQTop;

PROCEDURE ClipQRight;
BEGIN
  qy := (py - qy)*(XRight - qx) DIV (px - qx) + qy;
  qx := XRight;
END ClipQRight;

PROCEDURE ClipQLeft;
BEGIN
  qy := (py - qy)*(XLeft - qx) DIV (px - qx) + qy;
  qx := XLeft;
END ClipQLeft;

BEGIN
  code := 0;
  
  IF qy > YBottom THEN
    INC(code,8);
  ELSIF qy < YTop THEN
    INC(code,4);
  END;

  IF qx > XRight THEN
    INC(code,2);
  ELSIF qx < XLeft THEN
    INC(code,1);
  END;

  IF py > YBottom THEN
    INC(code,128);
  ELSIF py < YTop THEN
    INC(code,64);
  END;

  IF px > XRight THEN
    INC(code,32);
  ELSIF px < XLeft THEN
    INC(code,16);
  END;
  
  CASE code OF

   (**************  From Center ***************)

    00H : RETURN TRUE;
  | 01H : ClipQLeft; 
          RETURN TRUE;
  | 02H : ClipQRight; 
          RETURN TRUE;
  | 04H : ClipQTop;
          RETURN TRUE;
  | 05H : ClipQLeft;
          IF qy < YTop THEN
            ClipQTop;
          END;
          RETURN TRUE;
  | 06H : ClipQRight;
          IF qy < YTop THEN
            ClipQTop;
          END;
          RETURN TRUE;
  | 08H : ClipQBottom;
          RETURN TRUE;
  | 09H : ClipQLeft;
          IF qy > YBottom THEN
            ClipQBottom;
          END;
          RETURN TRUE;
  | 0AH : ClipQRight;
          IF qy > YBottom THEN
            ClipQBottom;
          END;
          RETURN TRUE;

  (**************  From Left ***************)

  | 10H : ClipPLeft;
          RETURN TRUE;
  | 11H : RETURN FALSE;
  | 12H : ClipPLeft;
          ClipQRight;
          RETURN TRUE;
  | 14H : ClipPLeft;
          IF py < YTop THEN
            RETURN FALSE;
          ELSE
            ClipQTop;
            RETURN TRUE;
          END;
  | 15H : RETURN FALSE;
  | 16H : ClipPLeft;
          IF py < YTop THEN
            RETURN FALSE;
          ELSE
            ClipQTop;
            IF qx > XRight THEN
              ClipQRight;
            END;
            RETURN TRUE;
          END;
  | 18H : ClipPLeft;
          IF py > YBottom THEN
            RETURN FALSE;
          ELSE
            ClipQBottom;
            RETURN TRUE;
          END;
  | 19H : RETURN FALSE;
  | 1AH : ClipPLeft;
          IF py > YBottom THEN
            RETURN FALSE;
          ELSE
            ClipQBottom;
            IF qx > XRight THEN
              ClipQRight;
            END;
            RETURN TRUE;
          END;

  (**************  From Right ***************)

  | 20H : ClipPRight;
          RETURN TRUE;
  | 21H : ClipPRight;
          ClipQLeft;
          RETURN TRUE;
  | 22H : RETURN FALSE;
  | 24H : ClipPRight;
          IF py < YTop THEN
            RETURN FALSE;
          ELSE
            ClipQTop;
            RETURN TRUE;
          END;
  | 25H : ClipPRight;
          IF py < YTop THEN
            RETURN FALSE;
          ELSE
            ClipQTop;
            IF qx < XLeft THEN
              ClipQLeft;
            END;
            RETURN TRUE;
          END;
  | 26H : RETURN FALSE;
  | 28H : ClipPRight;
          IF py > YBottom THEN
            RETURN FALSE;
          ELSE
            ClipQBottom;
            RETURN TRUE;
          END;
  | 29H : ClipPRight;
          IF py > YBottom THEN
            RETURN FALSE;
          ELSE
            ClipQBottom;
            IF qx < XLeft THEN
              ClipQLeft;
            END;
            RETURN TRUE;
          END;
  | 2AH : RETURN FALSE;
   
  (**************  From Top ***************)

  | 40H : ClipPTop;
          RETURN TRUE;
  | 41H : ClipPTop;
          IF px < XLeft THEN
            RETURN FALSE;
          ELSE
            ClipQLeft;
            IF qy < YTop THEN
              ClipQTop;
            END;
            RETURN TRUE;
          END;
  | 42H : ClipPTop;
          IF px > XRight THEN
            RETURN FALSE;
          ELSE
            ClipQRight;
            RETURN TRUE;
          END;
  | 44H : RETURN FALSE;
  | 45H : RETURN FALSE;
  | 46H : RETURN FALSE;
  | 48H : ClipPTop;
          ClipQBottom;
          RETURN TRUE;
  | 49H : ClipPTop;
          IF px < XLeft THEN
            RETURN FALSE;
          ELSE
            ClipQLeft;
            IF qy > YBottom THEN
              ClipQBottom;
            END;
            RETURN TRUE;
          END;
  | 4AH : ClipPTop;
          IF px > XRight THEN
            RETURN FALSE;
          ELSE
            ClipQRight;
            IF qy > YBottom THEN
              ClipQBottom;
            END;
            RETURN TRUE;
          END;

  (**************  From Bottom ***************)

  | 50H : ClipPLeft;
          IF py < YTop THEN
            ClipPTop;
          END;
          RETURN TRUE;
  | 51H : RETURN FALSE;
  | 52H : ClipQRight;
          IF qy < YTop THEN
            RETURN FALSE;
          ELSE
            ClipPTop;
            IF px < XLeft THEN
              ClipPLeft;
            END;
            RETURN TRUE;
          END;
  | 54H : RETURN FALSE;
  | 55H : RETURN FALSE;
  | 56H : RETURN FALSE;
  | 58H : ClipQBottom;
          IF qx < XLeft THEN
            RETURN FALSE;
          ELSE
            ClipPTop;
            IF px < XLeft THEN
              ClipPLeft;
            END;
            RETURN TRUE;
          END;
  | 59H : RETURN FALSE;
  | 5AH : ClipPLeft;
          IF py > YBottom THEN
            RETURN FALSE;
          ELSE
            ClipQRight;
            IF qy < YTop THEN
              RETURN FALSE;
            ELSE
              IF py < YTop THEN
                ClipPTop;
              END;
              IF qy > YBottom THEN
                ClipQBottom;
              END;
              RETURN TRUE;
            END;
          END;

  (**************  From Lower Right ***************)

  | 60H : ClipPRight;
          IF py < YTop THEN
            ClipPTop;
          END;
          RETURN TRUE;
  | 61H : ClipQLeft;
          IF qy < YTop THEN
            RETURN FALSE;
          ELSE
            ClipPTop;
            IF px > XRight THEN
              ClipPRight;
            END;
            RETURN TRUE;
          END;
  | 62H : RETURN FALSE;
  | 64H : RETURN FALSE;
  | 65H : RETURN FALSE;
  | 66H : RETURN FALSE;
  | 68H : ClipQBottom;
          IF qx > XRight THEN
            RETURN FALSE;
          ELSE
            ClipPRight;
            IF py < YTop THEN
              ClipPTop;
            END;
            RETURN TRUE;
          END;
  | 69H : ClipQLeft;
          IF qy < YTop THEN
            RETURN FALSE;
          ELSE
            ClipPRight;
            IF py > YBottom THEN
              RETURN FALSE;
            ELSE
              IF qy > YBottom THEN
                ClipQBottom;
              END;
              IF py < YTop THEN
                ClipPTop;
              END;
              RETURN TRUE;
            END;
          END;
  | 6AH : RETURN FALSE;

  (**************  From Bottom ***************)
   
  | 80H : ClipPBottom;
          RETURN TRUE;
  | 81H : ClipPBottom;
          IF px < XLeft THEN
            RETURN FALSE;
          ELSE
            ClipQLeft;
            RETURN TRUE;
          END;
  | 82H : ClipPBottom;
          IF px > XRight THEN
            RETURN FALSE;
          ELSE
            ClipQRight;
            RETURN TRUE;
          END;
  | 84H : ClipPBottom;
          ClipQTop;
          RETURN TRUE;
  | 85H : ClipPBottom;
          IF px < XLeft THEN
            RETURN FALSE;
          ELSE
            ClipQLeft;
            IF qy < YTop THEN
              ClipQTop;
            END;
            RETURN TRUE;
          END;
  | 86H : ClipPBottom;
          IF px > XRight THEN
            RETURN FALSE;
          ELSE
            ClipQRight;
            IF qy < YTop THEN
              ClipQTop;
            END;
            RETURN TRUE;
          END;
  | 88H : RETURN FALSE;
  | 89H : RETURN FALSE;
  | 8AH : RETURN FALSE;

  (**************  From Bottom ***************)

  | 90H : ClipPLeft;
          IF py > YBottom THEN
            ClipPBottom;
          END;
          RETURN TRUE;
  | 91H : RETURN FALSE;
  | 92H : ClipQRight;
          IF qy > YBottom THEN
            RETURN FALSE;
          ELSE
            ClipPBottom;
            IF px < XLeft THEN
              ClipPLeft;
            END;
            RETURN TRUE;
          END;
  | 94H : ClipQTop;
          IF qx < XLeft THEN
            RETURN FALSE;
          ELSE
            ClipPLeft;
            IF py > YBottom THEN
              ClipPBottom;
            END;
            RETURN TRUE;
          END;
  | 95H : RETURN FALSE;
  | 96H : ClipPLeft;
          IF py < YTop THEN
            RETURN FALSE;
          ELSE
            ClipQRight;
            IF qy > YBottom THEN
              RETURN FALSE;
            ELSE
              IF py > YBottom THEN
                ClipPBottom;
              END;
              IF qy < YTop THEN
                ClipQTop;
              END;
              RETURN TRUE;
            END;
          END;
  | 98H : RETURN FALSE;
  | 99H : RETURN FALSE;
  | 9AH : RETURN FALSE;

  (**************  From Bottom ***************)

  | 0A0H : ClipPRight;
           IF py > YBottom THEN
             ClipPBottom;
           END;
           RETURN TRUE;
  | 0A1H : ClipQLeft;
           IF qy > YBottom THEN
             RETURN FALSE;
           ELSE
             ClipPBottom;
             IF px > XRight THEN 
               ClipPRight;
             END;
             RETURN TRUE;
           END;
  | 0A2H : RETURN FALSE;
  | 0A4H : ClipQTop;
           IF qx > XRight THEN
             RETURN FALSE;
           ELSE
             ClipPRight;
             IF py > YBottom THEN
               ClipPBottom;
             END;
             RETURN TRUE;
           END;
  | 0A5H : ClipQLeft;
           IF qy > YBottom THEN
             RETURN FALSE;
           ELSE
             ClipPRight;
             IF py < YTop THEN
               RETURN FALSE;
             ELSE
               IF qy < YTop THEN
                 ClipQTop;
               END;
               IF py > YBottom THEN
                 ClipPBottom;
               END;
               RETURN TRUE;
             END;
           END;
  | 0A6H : RETURN FALSE;
  | 0A8H : RETURN FALSE;
  | 0A9H : RETURN FALSE;
  | 0AAH : RETURN FALSE;

  (************** Error Trap ***************)

  ELSE  (* Undefined Code *)

    RETURN FALSE;

  END; (* CASE code *)

END clip2d;

BEGIN
  XLeft   := 0;
  XRight  := 319;
  YTop    := 0;
  YBottom := 199;
END clip2d.
