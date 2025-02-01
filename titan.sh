#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # 색상 초기화

# 변수 정의
PACKAGE_NAME="titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz"
DIR_NAME="titan-edge_v0.1.20_246b9dd_linux-amd64"

# 설치 과정 선택
echo -e "${YELLOW}설치 과정을 선택하세요:${NC}"
echo -e "1) Edge 노드 설치"
echo -e "2) Galileo 노드 설치"
echo -e "${YELLOW}두가지 노드 모두 구동해주세요.${NC}"
read -p "번호를 선택하세요 (1 또는 2): " install_choice

if [ "$install_choice" = "1" ]; then
    echo -e "${YELLOW}[Edge 노드 설치를 시작합니다]${NC}"
    # 1. 기존 작업 디렉토리 삭제
    if [ -d "$DIR_NAME" ]; then
        echo -e "${YELLOW}기존 작업 디렉토리를 삭제합니다...${NC}"
        rm -rf "$DIR_NAME"
    fi
    sudo rm /usr/local/bin/titan-edge

    # 2. 기존 패키지 삭제
    if [ -f "$PACKAGE_NAME" ]; then
        echo -e "${YELLOW}기존 패키지를 삭제합니다...${NC}"
        rm -f "$PACKAGE_NAME"
    fi

    # 3. 패키지 다운로드
    echo -e "${YELLOW}패키지를 다운로드합니다...${NC}"
    wget https://github.com/Titannet-dao/titan-node/releases/download/v0.1.20/titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz

    # 4. 다운로드한 파일 압축 해제
    echo -e "${YELLOW}패키지를 추출합니다...${NC}"
    tar -xzvf "$PACKAGE_NAME"

    # 5. 작업 폴더로 이동
    cd "$DIR_NAME" || { echo -e "${RED}디렉토리로 이동 실패${NC}"; exit 1; }

    # 6. 권한 설정 및 파일 복사
    echo -e "${YELLOW}파일을 복사합니다...${NC}"
    sudo cp titan-edge /usr/local/bin
    sudo cp libgoworkerd.so /usr/local/lib

    # 7. 환경 변수 설정
    echo -e "${YELLOW}환경 변수를 설정합니다...${NC}"
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

    # 8. 식별코드 얻기
    echo -e "${YELLOW}해당 사이트에 방문하여 식별코드를 얻으세요: ${NC}"
    echo -e "${YELLOW}https://titannet.gitbook.io/titan-network-en/resource-network-test/bind-the-identity-code${NC}"

    # 9. 사용자로부터 식별 코드 입력 받기
    read -p "$(echo -e ${YELLOW}식별 코드를 입력하세요: ${NC})" identifier

    # config.toml 포트 변경
    echo -e "${YELLOW}config.toml 파일의 포트를 1235로 변경합니다.${NC}"
    sed -i 's/ListenAddress = "0.0.0.0:1234"/ListenAddress = "0.0.0.0:1235"/' /root/.titanedge/config.toml

    # 바이너리에서 1234 포트를 1235로 변경
    echo -e "${YELLOW}titan-edge 바이너리에서 포트를 1235로 변경합니다.${NC}"
    sed -i 's/0.0.0.0:1234/0.0.0.0:1235/g' /usr/local/bin/titan-edge

    # 10. 바인드 명령 실행
    echo -e "${YELLOW}바인드 명령을 실행합니다...${NC}"
    titan-edge bind --hash="$identifier" https://api-test1.container1.titannet.io/api/v2/device/binding

    # 현재 사용 중인 포트 확인
    used_ports=$(netstat -tuln | awk '{print $4}' | grep -o '[0-9]*$' | sort -u)

    # 각 포트에 대해 ufw allow 실행
    for port in $used_ports; do
        echo -e "${GREEN}포트 ${port}을(를) 허용합니다.${NC}"
        sudo ufw allow $port
    done

    echo -e "${GREEN}모든 사용 중인 포트가 허용되었습니다.${NC}"

    # 11.데몬 시작
    echo -e "${YELLOW}titan-edge 데몬을 시작합니다...컨트롤 A+D로 스크린을 종료해주세요${NC}"
    echo -e "${GREEN}스크립트 작성자: https://t.me/kjkresearch${NC}"
    titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0

elif [ "$install_choice" = "2" ]; then
    echo -e "${YELLOW}[Galileo 노드 설치를 시작합니다]${NC}"

    echo -e "${GREEN}필수 패키지를 설치합니다.${NC}"
    sudo apt update && sudo apt install -y snapd unzip wget
    sudo systemctl enable --now snapd.socket
    sudo snap install multipass

    echo -e "${GREEN}패키지를 설치합니다.${NC}"
    wget https://pcdn.titannet.io/test4/bin/agent-linux.zip
    sudo mkdir -p /opt/titanagent
    sudo unzip -o agent-linux.zip -d /opt/titanagent
    
    # 기존 titanagent 폴더가 있다면 삭제
    if [ -d "/opt/titanagent" ]; then
        echo -e "${YELLOW}기존 titanagent 폴더를 삭제합니다...${NC}"
        sudo rm -rf /opt/titanagent
    fi
    
    wget https://pcdn.titannet.io/test4/bin/agent-linux.zip
    sudo mkdir -p /opt/titanagent
    sudo unzip -o agent-linux.zip -d /opt/titanagent
    
    # apps 디렉토리 생성
    sudo mkdir -p /opt/titanagent/apps
    
    # config.json 파일 생성 및 올바른 JSON 구조 설정
    sudo bash -c 'cat > /opt/titanagent/apps/config.json << EOL
[
    {
        "name": "",
        "version": "",
        "status": "",
        "config": {}
    }
]
EOL'

    # 권한 설정
    sudo chmod 644 /opt/titanagent/apps/config.json
    sudo chmod -R 755 /opt/titanagent

    # 식별코드 얻기
    echo -e "${YELLOW}해당 사이트에 방문하여 식별코드를 얻으세요: ${NC}"
    echo -e "${YELLOW}https://test4.titannet.io/walletManagement${NC}"

    # 식별 코드 입력 받기
    read -p "$(echo -e ${YELLOW}식별 코드를 입력하세요: ${NC})" identifier

    # 노드구동
    cd /opt/titanagent
    chmod +x agent
    ./agent --working-dir=/opt/titanagent --server-url=https://test4-api.titannet.io --key="$identifier"
else

    echo -e "${RED}잘못된 선택입니다. 1 또는 2를 선택해주세요.${NC}"
    exit 1
fi
