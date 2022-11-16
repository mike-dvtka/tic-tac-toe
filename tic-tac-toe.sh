#!/bin/bash
declare -A matrix
n=3
num_rows=$n
num_columns=$n
end=0
max=8
player=1
mark="X"
error=0
win=0
loadGameError=1
computerPlayerError=1
computerPlayer=0
computerPlayerDecision=0
computerDrawPosition=0

for ((i=1;i<=num_rows;i++)) do
    for ((j=1;j<=num_columns;j++)) do
        matrix[$i,$j]=" "
    done
done

function drawBoard {
    echo "  | A   B   C "
    echo "--------------"
    echo "1 | ${matrix[1,1]} | ${matrix[2,1]} | ${matrix[3,1]} "
    echo "  |-----------"
    echo "2 | ${matrix[1,2]} | ${matrix[2,2]} | ${matrix[3,2]} "
    echo "  |-----------"
    echo "3 | ${matrix[1,3]} | ${matrix[2,3]} | ${matrix[3,3]} "
    printf "\n"
}

function saveToArray {
    row=$1
    column=$2
    mark=$3
    matrix[$row,$column]=$mark
    checkMatrixForWins $row $column $mark
    error=0
    computerDrawPosition=0
}

function checkMatrixForWins {
    row=$1
    column=$2
    mark=$3

    for ((k=1;k<n+1;k++)) do
        if [[ ${matrix[$row,$k]} != $mark ]]
        then
            break
        fi
        if [[ $k -eq $n ]]
        then
            win=1
            break
        fi
    done

    for ((k=1;k<n+1;k++)) do
        if [[ ${matrix[$k,$column]} != $mark ]]
        then
            break
        fi
        if [[ $k -eq $n ]]
        then
            win=1
            break
        fi
    done

    if [[ $row == $column ]]
    then
        for ((k=1;k<n+1;k++)) do
            if [[ ${matrix[$k,$k]} != $mark ]]
            then
                break
            fi
            if [[ $k -eq $n ]]
            then
                win=1
                break
            fi
        done
    fi

    if [[ $((row+column)) == $((n+1)) ]]
    then
        for ((k=1;k<n+1;k++)) do
            if [[ ${matrix[$k,$(((n+1)-k))]} != $mark ]]
            then
                break
            fi
            if [[ $k -eq $n ]]
            then
                win=1
                break
            fi
        done
    fi
}

function checkIfPositionAvailable {
    row=$1
    column=$2
    mark=$3

    if [[ ${matrix[$row,$column]} == " " ]]
    then
        saveToArray $row $column $mark
    else
        if [[ $computerPlayerDecision -eq 1 ]]
        then
            computerDrawPosition=1
        else
            error=1
            echo "Pozycja zablokowana"
        fi
    fi
}

function checkIfCorrectColumn {
    row=$1
    column=$2
    mark=$3

    if [[ ${column:1:1} == "1" ]]
    then
        checkIfPositionAvailable $row 1 $mark
    elif [[ ${column:1:1} == "2" ]]
    then
        checkIfPositionAvailable $row 2 $mark
    elif [[ ${column:1:1} == "3" ]]
    then
        checkIfPositionAvailable $row 3 $mark
    else
        error=1
        echo "Nieprawidlowy numer kolumny";
    fi
}

function saveGame {
    fileName=$1
    > $fileName.txt
    for ((i=1;i<=num_rows;i++)) do
        for ((j=1;j<=num_columns;j++)) do
            printf "%s\n" "${matrix[$i,$j]}" >> $fileName.txt
        done
    done
    printf "%s\n" "$player" >> $fileName.txt
    printf "%s\n" "$end" >> $fileName.txt
    printf "%s\n" "$mark" >> $fileName.txt
    printf "%s\n" "$error" >> $fileName.txt
    printf "%s\n" "$win" >> $fileName.txt
    printf "%s\n" "$loadGameError" >> $fileName.txt
    printf "%s\n" "$computerPlayerError" >> $fileName.txt
    printf "%s\n" "$computerPlayer" >> $fileName.txt
    printf "%s\n" "$computerPlayerDecision" >> $fileName.txt
    printf "%s\n" "$computerDrawPosition" >> $fileName.txt
}

function loadGame {
    fileName=$1
    var=1
    for ((i=1;i<=num_rows;i++)) do
        for ((j=1;j<=num_columns;j++)) do
            matrix[$i,$j]=$(sed -n ${var}p $fileName.txt)
            ((var++))
        done
    done
    player=$(sed -n 10p $fileName.txt)
    end=$(sed -n 11p $fileName.txt)
    mark=$(sed -n 12p $fileName.txt)
    error=$(sed -n 13p $fileName.txt)
    win=$(sed -n 14p $fileName.txt)
    loadGameError=$(sed -n 15p $fileName.txt)
    computerPlayerError=$(sed -n 16p $fileName.txt)
    computerPlayer=$(sed -n 17p $fileName.txt)
    computerPlayerDecision=$(sed -n 18p $fileName.txt)
    computerDrawPosition=$(sed -n 19p $fileName.txt)
}

function playerTerminal {
    read -p "Gracz $player prosze wpisac pole (np. a1). Jesli chcesz zapisac gre wpisz 's': " spot
    if [[ ${spot::1} == "a" || ${spot::1} == "A" ]]
    then
        checkIfCorrectColumn 1 $spot $mark
    elif [[ ${spot::1} == "b" || ${spot::1} == "B" ]]
    then
        checkIfCorrectColumn 2 $spot $mark
    elif [[ ${spot::1} == "c" || ${spot::1} == "C" ]]
    then
        checkIfCorrectColumn 3 $spot $mark
    elif [[ ${spot::1} == "s" || ${spot::1} == "S" ]]
    then
        read -p "Podaj nazwe pliku (bez rozszerzenia): " file
        saveGame $file
        error=1
        printf "\n"
        echo "Zapisano do pliku $file.txt"
        printf "\n"
        drawBoard matrix
    else
        error=1
        echo "Nieprawidlowa litera"
    fi
    if [ $error -eq 0 ]
    then
        printf "\n"
        drawBoard matrix
        if [ $win -eq 1 ]
        then
            echo "Gracz $player wygrywa!"
            exit 0
        else
            end=$[end+1]
            if [ $player -eq 1 ]
            then
                player=2
                mark="O"
            else
                player=1
                mark="X"
            fi
        fi
    fi
}

function computer {
    computerPlayerDecision=1
    correctPosition=0
    until [ $correctPosition -eq 1 ]
    do
        posX=$(shuf -i 1-3 -n 1)
        posY=$(shuf -i 1-3 -n 1)
        checkIfPositionAvailable $posX $posY $mark
        if [[ $computerDrawPosition -eq 0 ]]
        then
            echo "Komputer wykonal ruch"
            printf "\n"
            drawBoard matrix
            if [ $win -eq 1 ]
            then
                echo "Komputer wygrywa!"
                exit 0
            else
                end=$[end+1]
                correctPosition=1
                computerPlayerDecision=0
                player=1
                mark="X"
            fi
        fi
    done
    
}

printf "\n"
until [ $loadGameError -eq 0 ]
do
    read -p "Czy chcesz wczytac gre? (y/n): " loadGameDecision
    if [[ ${loadGameDecision::1} == "y" || ${loadGameDecision::1} == "Y" ]]
    then
        read -p "Podaj nazwe pliku (bez rozszerzenia): " openFile
        if [ -f "$openFile.txt" ]
        then
            loadGame $openFile
            loadGameError=0
        else
            echo "Plik $openFile.txt nie istnieje"
        fi
    elif [[ ${loadGameDecision::1} == "n" || ${loadGameDecision::1} == "N" ]]
    then
        loadGameError=0
        until [ $computerPlayerError -eq 0 ]
        do
            read -p "Czy chcesz grac z komputerem? (y/n): " computerGameDecision
            if [[ ${computerGameDecision::1} == "y" || ${computerGameDecision::1} == "Y" ]]
            then
                computerPlayerError=0
                computerPlayer=1
            elif [[ ${loadGameDecision::1} == "n" || ${loadGameDecision::1} == "N" ]]
            then
                computerPlayerError=0
            else
                echo "Wpisz poprawna litere"
            fi
        done
    else
        echo "Wpisz poprawna litere"
    fi
done
printf "\n"
echo "Zaczynamy"
printf "\n"
drawBoard matrix

until [ $end -gt $max ]
do
    if [ $player -eq 1 ]
    then
        playerTerminal
    elif [ $player -eq 2 ]
    then
        if [ $computerPlayer -eq 1 ]
        then
            computer
        else
            playerTerminal
        fi
    else
        echo "Player number error"
        exit 0
    fi
done

echo "Remis!"
exit 0