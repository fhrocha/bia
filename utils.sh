erro() {
    echo "ERRO! ==> $1";
}

checar_ultimo_commando() {
    if [ $? != 0 ]; then
        erro "Erro no deploy. Parando tudo..."
        exit 1;
    fi
}