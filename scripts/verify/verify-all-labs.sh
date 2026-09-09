#!/usr/bin/env bash
# NovaShop — Tüm Laboratuvarlar İçin Ana Doğrulama Koşucusu (Master Test Runner)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "========================================================"
echo "   NovaShop DevOps Store — Tüm Laboratuvarlar Testi    "
echo "========================================================"

TOTAL=0
PASSED=0
FAILED=0

run_test() {
    local script="$1"
    local desc="$2"
    shift 2
    TOTAL=$((TOTAL + 1))
    echo ""
    echo "▶ Test [$TOTAL]: $desc ($script)"
    if bash "$SCRIPT_DIR/$script" "$@" >/dev/null 2>&1; then
        echo "  [PASS] $desc"
        PASSED=$((PASSED + 1))
    else
        echo "  [WARN/FAIL] $desc (Ayrıntı için: bash scripts/verify/$script)"
        FAILED=$((FAILED + 1))
    fi
}

# Statik ve yerel ortamda koşulabilen doğrulamalar
run_test "verify-lab-01.sh" "LAB-01 Git & GitHub Doğrulaması"
run_test "verify-lab-03.sh" "LAB-03 Docker & Compose Doğrulaması" 8888 localhost
run_test "verify-lab-05.sh" "LAB-05 GitHub Actions CI/CD Doğrulaması"
run_test "verify-lab-06.sh" "LAB-06 Kubernetes & Helm Doğrulaması"
run_test "verify-lab-08.sh" "LAB-08 DevSecOps Güvenlik Kapıları Doğrulaması"
run_test "verify-lab-09.sh" "LAB-09 ArgoCD GitOps Doğrulaması"
run_test "verify-lab-10.sh" "LAB-10 Gözlemlenebilirlik ve Metrik Doğrulaması" 8888 localhost
run_test "verify-lab-11.sh" "LAB-11 Merkezi Günlükleme Doğrulaması"
run_test "verify-lab-12.sh" "LAB-12 Terraform IaC Doğrulaması"
run_test "verify-lab-14.sh" "LAB-14 Amazon ECS Fargate Doğrulaması"

echo ""
echo "========================================================"
echo "   Özet: Toplam: $TOTAL | Başarılı: $PASSED | İnceleme: $FAILED"
echo "========================================================"
